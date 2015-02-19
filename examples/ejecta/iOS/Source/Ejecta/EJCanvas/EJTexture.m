#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "EJTexture.h"
#import "EJConvertWebGL.h"

#import "EJSharedTextureCache.h"
#import "EJJavaScriptView.h"

#define PVR_TEXTURE_FLAG_TYPE_MASK 0xff

enum {
	kPVRTextureFlagTypePVRTC_2 = 24,
	kPVRTextureFlagTypePVRTC_4
};

typedef struct {
	uint32_t headerLength;
	uint32_t height;
	uint32_t width;
	uint32_t numMipmaps;
	uint32_t flags;
	uint32_t dataLength;
	uint32_t bpp;
	uint32_t bitmaskRed;
	uint32_t bitmaskGreen;
	uint32_t bitmaskBlue;
	uint32_t bitmaskAlpha;
	uint32_t pvrTag;
	uint32_t numSurfs;
} PVRTextureHeader;

@implementation EJTexture
@synthesize contentScale;
@synthesize format;
@synthesize drawFlippedY;

@synthesize lazyLoaded;

- (id)initEmptyForWebGL {
	// For WebGL textures; this will not create a textureStorage
	
	if( self = [super init] ) {
		contentScale = 1;
		
		params[kEJTextureParamMinFilter] = GL_LINEAR;
		params[kEJTextureParamMagFilter] = GL_LINEAR;
		params[kEJTextureParamWrapS] = GL_REPEAT;
		params[kEJTextureParamWrapT] = GL_REPEAT;
	}
	return self;
}

- (id)initWithPath:(NSString *)path {
	// For loading on the main thread (blocking)
	
	if( self = [super init] ) {
		contentScale = 1;
		fullPath = [path retain];
		
		NSMutableData *pixels = [self loadPixelsFromPath:path];
		if( pixels ) {
			[self createWithPixels:pixels format:GL_RGBA];
		}
	}

	return self;
}

+ (id)cachedTextureWithPath:(NSString *)path loadOnQueue:(NSOperationQueue *)queue callback:(NSOperation *)callback {
	// For loading on a background thread (non-blocking), but tries the cache first
	
	// Only try the cache if path is not a data URI
	BOOL isDataURI = [path hasPrefix:@"data:"];
	
	EJTexture *texture = !isDataURI
		? EJSharedTextureCache.instance.textures[path]
		: nil;
	
	if( texture ) {
		// We already have a texture, but it may hasn't finished loading yet. If
		// the texture's loadCallback is still present, add it as an dependency
		// for the current callback.
		
		if( texture->loadCallback ) {
			[callback addDependency:texture->loadCallback];
		}
		[NSOperationQueue.mainQueue addOperation:callback];
	}
	else {
		// Create a new texture and add it to the cache
		texture = [[EJTexture alloc] initWithPath:path loadOnQueue:queue callback:callback];
		
		if( !isDataURI ) {
			EJSharedTextureCache.instance.textures[path] = texture;
			texture->cached = true;
		}
		[texture autorelease];
	}
	return texture;
}

- (id)initWithPath:(NSString *)path loadOnQueue:(NSOperationQueue *)queue callback:(NSOperation *)callback {
	// For loading on a background thread (non-blocking)
	// This will defer loading for local images
	
	if( self = [super init] ) {
		contentScale = 1;
		fullPath = [path retain];
		
		BOOL isURL = [path hasPrefix:@"http:"] || [path hasPrefix:@"https:"];
		BOOL isDataURI = !isURL && [path hasPrefix:@"data:"];
		
		// Neither a URL nor a data URI? We can lazy load the texture. Just add the callback
		// to the load queue and return
		if( !isURL && !isDataURI ) {
			lazyLoaded = true;
			format = GL_RGBA;
			[NSOperationQueue.mainQueue addOperation:callback];
			return self;
		}
		
		
		loadCallback = [[NSBlockOperation alloc] init];
		
		// Load the image file in a background thread
		[queue addOperationWithBlock:^{
			NSMutableData *pixels = [self loadPixelsFromPath:path];
			
			// Upload the pixel data in the main thread, otherwise the GLContext gets confused.	
			// We could use a sharegroup here, but it turned out quite buggy and has little
			// benefits - the main bottleneck is loading the image file.
			[loadCallback addExecutionBlock:^{
				if( pixels ) {
					[self createWithPixels:pixels format:GL_RGBA];
				}
				[loadCallback release];
				loadCallback = nil;
			}];
			[callback addDependency:loadCallback];
			
			[NSOperationQueue.mainQueue addOperation:loadCallback];
			[NSOperationQueue.mainQueue addOperation:callback];
		}];
	}
	return self;
}

- (id)initWithWidth:(int)widthp height:(int)heightp {
	// Create an empty RGBA texture
	return [self initWithWidth:widthp height:heightp format:GL_RGBA];
}

- (id)initWithWidth:(int)widthp height:(int)heightp format:(GLenum)formatp {
	// Create an empty texture
	
	if( self = [super init] ) {
		contentScale = 1;
		
		width = widthp;
		height = heightp;
		dimensionsKnown = true;
		[self createWithPixels:NULL format:formatp];
	}
	return self;
}

- (id)initWithWidth:(int)widthp height:(int)heightp pixels:(NSData *)pixels {
	// Creates a texture with the given pixels
	
	if( self = [super init] ) {
		contentScale = 1;
		
		width = widthp;
		height = heightp;
		dimensionsKnown = true;
		[self createWithPixels:pixels format:GL_RGBA];
	}
	return self;
}

- (id)initAsRenderTargetWithWidth:(int)widthp height:(int)heightp fbo:(GLuint)fbop contentScale:(float)contentScalep {
	if( self = [self initWithWidth:widthp*contentScalep height:heightp*contentScalep] ) {
		fbo = fbop;
		contentScale = contentScalep;
	}
	return self;
}

- (id)initWithUIImage:(UIImage *)image {
	if( self = [super init] ) {
		if( [UIScreen mainScreen].scale == 2 ) {
			contentScale = 2;
		}
		else {
			contentScale = 1;
		}

		NSMutableData *pixels = [self loadPixelsFromUIImage:image];
		if( pixels ) {
			[self createWithPixels:pixels format:GL_RGBA];
		}
	}
	return self;
}

- (void)dealloc {
	if( cached ) {
		[EJSharedTextureCache.instance.textures removeObjectForKey:fullPath];
	}
	[loadCallback release];
	
	[fullPath release];
	[textureStorage release];
	[super dealloc];
}

- (void)maybeReleaseStorage {
	// Releases the texture storage if it can be easily reloaded from
	// a local file
	if( lazyLoaded && textureStorage ) {
	
		// Make sure this isnt' the currently bound texture
		GLint boundTexture = 0;
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &boundTexture);
		if( boundTexture != textureStorage.textureId ) {
			[textureStorage release];
			textureStorage = nil;
		}
	}
}

- (void)ensureMutableKeepPixels:(BOOL)keepPixels forTarget:(GLenum)target {

	// If we have a TextureStorage but it's not mutable (i.e. created by Canvas2D) and
	// we're not the only owner of it, we have to create a new TextureStorage.
	// FIXME: If the texture is compressed, we simply ignore this check and use the compressed
	// TextureStorage
	if( textureStorage && textureStorage.immutable && textureStorage.retainCount > 1 && !isCompressed ) {
	
		// Keep pixel data of the old TextureStorage when creating the new?
		if( keepPixels ) {
			NSMutableData *pixels = self.pixels;
			if( pixels ) {
				[self createWithPixels:pixels format:GL_RGBA target:target];
			}
		}
		else {
			[textureStorage release];
			textureStorage = NULL;
		}
	}
	
	if( !textureStorage ) {
		textureStorage = [[EJTextureStorage alloc] init];
	}
}

- (NSTimeInterval)lastUsed {
	return textureStorage.lastBound;
}

// When accessing the .textureId, .width, .height or .contentScale we need to
// ensure that lazyLoaded textures are actually loaded by now.

#define EJ_ENSURE_LAZY_LOADED_STORAGE() \
	if( !textureStorage && lazyLoaded ) { \
		NSMutableData *pixels = [self loadPixelsFromPath:fullPath]; \
		if( pixels ) { \
			[self createWithPixels:pixels format:GL_RGBA]; \
		} \
	}

- (GLuint)textureId {
	EJ_ENSURE_LAZY_LOADED_STORAGE();
	return textureStorage.textureId;
}

- (BOOL)isDynamic {
	return !!fbo;
}

- (short)width {
	if( dimensionsKnown ) {
		return width;
	}
	EJ_ENSURE_LAZY_LOADED_STORAGE();
	return width;
}

- (short)height {
	if( dimensionsKnown ) {
		return height;
	}
	EJ_ENSURE_LAZY_LOADED_STORAGE();
	return height;
}

- (float)contentScale {
	if( dimensionsKnown ) {
		return contentScale;
	}
	EJ_ENSURE_LAZY_LOADED_STORAGE();
	return contentScale;
}

- (id)copyWithZone:(NSZone *)zone {
	EJTexture *copy = [[EJTexture allocWithZone:zone] init];
	
	// This retains the textureStorage object and sets the associated properties
	[copy createWithTexture:self];
	
	// Copy texture parameters not handled by createWithTexture
	memcpy(copy->params, params, sizeof(EJTextureParams));
	copy->isCompressed = isCompressed;
	
	if( self.isDynamic && !isCompressed ) {
		// We want a static copy. So if this texture is used by an FBO, we have to
		// re-create the texture from pixels again
		[copy createWithPixels:self.pixels format:format];
	}

	return copy;
}

- (void)createWithTexture:(EJTexture *)other {
	[textureStorage release];
	[fullPath release];
	
	format = other->format;
	contentScale = other->contentScale;
	fullPath = [other->fullPath retain];
	
	width = other->width;
	height = other->height;
	isCompressed = other->isCompressed;
	lazyLoaded = other->lazyLoaded;
	dimensionsKnown = other->dimensionsKnown;
	
	textureStorage = [other->textureStorage retain];
}

- (void)createWithPixels:(NSData *)pixels format:(GLenum)formatp {
	[self createWithPixels:pixels format:formatp target:GL_TEXTURE_2D];
}

- (void)createWithPixels:(NSData *)pixels format:(GLenum)formatp target:(GLenum)target {
	// Release previous texture if we had one
	if( textureStorage ) {
		[textureStorage release];
		textureStorage = NULL;
	}
	
	// Set the default texture params for Canvas2D
	params[kEJTextureParamMinFilter] = GL_LINEAR;
	params[kEJTextureParamMagFilter] = GL_LINEAR;
	params[kEJTextureParamWrapS] = GL_CLAMP_TO_EDGE;
	params[kEJTextureParamWrapT] = GL_CLAMP_TO_EDGE;

	GLint maxTextureSize;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
	
	if( width > maxTextureSize || height > maxTextureSize ) {
		NSLog(@"Warning: Image %@ larger than MAX_TEXTURE_SIZE (%d)", fullPath ? fullPath : @"[Dynamic]", maxTextureSize);
		return;
	}
	format = formatp;
	
	GLint boundTexture = 0;
	GLenum bindingName = (target == GL_TEXTURE_2D)
		? GL_TEXTURE_BINDING_2D
		: GL_TEXTURE_BINDING_CUBE_MAP;
	glGetIntegerv(bindingName, &boundTexture);
	
	if( isCompressed ) {
		[self uploadCompressedPixels:pixels target:target];
	}
	else {
		textureStorage = [[EJTextureStorage alloc] initImmutable];
		[textureStorage bindToTarget:target withParams:params];
		glTexImage2D(target, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, pixels.bytes);
	}
	
	glBindTexture(target, boundTexture);
}

- (void)uploadCompressedPixels:(NSData *)pixels target:(GLenum)target {
	PVRTextureHeader *header = (PVRTextureHeader *) pixels.bytes;
	
    uint32_t formatFlags = header->flags & PVR_TEXTURE_FLAG_TYPE_MASK;
	
	GLenum internalFormat;
	uint32_t bpp;
	
	if( formatFlags == kPVRTextureFlagTypePVRTC_4 ) {
		internalFormat = GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
		bpp = 4;
	}
	else if( formatFlags == kPVRTextureFlagTypePVRTC_2 ) {
		internalFormat = GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
		bpp = 2;
	}
	else {
		NSLog(@"Warning: PVRTC Compressed Image %@ neither 2 nor 4 bits per pixel", fullPath);
		return;
	}
	
	
	// Create texture storage
	if( header->numMipmaps > 0 ) {
		params[kEJTextureParamMinFilter] = GL_LINEAR_MIPMAP_LINEAR;
	}
	
	textureStorage = [[EJTextureStorage alloc] initImmutable];
	[textureStorage bindToTarget:target withParams:params];
	
	// Upload all mip levels
	int mipWidth = width,
		mipHeight = height;
	
	
	uint8_t *bytes = ((uint8_t *)pixels.bytes) + header->headerLength;
	
	for( int mip = 0; mip < header->numMipmaps+1; mip++ ) {
		uint32_t widthBlocks = MAX(mipWidth / (16/bpp), 2);
		uint32_t heightBlocks = MAX(mipHeight / 4, 2);
		uint32_t size = widthBlocks * heightBlocks * 8;
		
		glCompressedTexImage2D(GL_TEXTURE_2D, mip, internalFormat, mipWidth, mipHeight, 0, size, bytes);
		bytes += size;

		mipWidth = MAX(mipWidth >> 1, 1);
		mipHeight = MAX(mipHeight >> 1, 1);
	}
}

- (void)updateWithPixels:(NSData *)pixels atX:(int)sx y:(int)sy width:(int)sw height:(int)sh {	
	int boundTexture = 0;
	glGetIntegerv(GL_TEXTURE_BINDING_2D, &boundTexture);
	
	glBindTexture(GL_TEXTURE_2D, textureStorage.textureId);
	glTexSubImage2D(GL_TEXTURE_2D, 0, sx, sy, sw, sh, format, GL_UNSIGNED_BYTE, pixels.bytes);
	
	glBindTexture(GL_TEXTURE_2D, boundTexture);
}

- (NSMutableData *)pixels {
	EJ_ENSURE_LAZY_LOADED_STORAGE();
	
	GLint boundFrameBuffer;
	GLuint tempFramebuffer;
	glGetIntegerv( GL_FRAMEBUFFER_BINDING, &boundFrameBuffer );
	
	// If this texture doesn't have an FBO (i.e. its not used as the backing store
	// for an offscreen canvas2d), we have to create a new, temporary framebuffer
	// containing the texture. We can then read the pixel data using glReadPixels
	// as usual
	if( !fbo ) {
		glGenFramebuffers(1, &tempFramebuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, tempFramebuffer);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureStorage.textureId, 0);
	}
	else {
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	}
	
	int size = width * height * EJGetBytesPerPixel(GL_UNSIGNED_BYTE, format);
	NSMutableData *data = [NSMutableData dataWithLength:size];
	glReadPixels(0, 0, width, height, format, GL_UNSIGNED_BYTE, data.mutableBytes);
	
	glBindFramebuffer(GL_FRAMEBUFFER, boundFrameBuffer);
	
	
	if( !fbo ) {
		glDeleteFramebuffers(1, &tempFramebuffer);
	}
	
	return data;
}

- (NSMutableData *)loadPixelsFromPath:(NSString *)path {
	BOOL isURL = [path hasPrefix:@"http:"] || [path hasPrefix:@"https:"];
	BOOL isDataURI = !isURL && [path hasPrefix:@"data:"];
	
	// Try @2x texture?
	if( !isURL && !isDataURI && [UIScreen mainScreen].scale == 2 ) {
		NSString *path2x = [[[path stringByDeletingPathExtension]
			stringByAppendingString:@"@2x"]
			stringByAppendingPathExtension:[path pathExtension]];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath:path2x] ) {
			contentScale = 2;
			path = path2x;
		}
	}
	
	
	NSMutableData *pixels;
	if( isDataURI || isURL ) {
		// Load directly from a Data URI string or an URL
		UIImage *tmpImage = [[UIImage alloc] initWithData:
			[NSData dataWithContentsOfURL:[NSURL URLWithString:path]]];
		
		if( !tmpImage ) {
			if( isDataURI ) {
				NSLog(@"Error Loading image from Data URI.");
			}
			if( isURL ) {
				NSLog(@"Error Loading image from URL: %@", path);
			}
			return NULL;
		}
		pixels = [self loadPixelsFromUIImage:tmpImage];
		[tmpImage release];
	}
	
	else if( [path.pathExtension isEqualToString:@"pvr"] ) {
		// Compressed PVRTC? Only load raw data bytes
		pixels = [NSMutableData dataWithContentsOfFile:path];
		if( !pixels ) {
			NSLog(@"Error Loading image %@ - not found.", path);
			return NULL;
		}
		PVRTextureHeader *header = (PVRTextureHeader *)pixels.bytes;
		width = header->width;
		height = header->height;
		dimensionsKnown = true;
		isCompressed = true;
	}
	
	else {
		// Use UIImage for PNG, JPG and everything else
		UIImage *tmpImage = [[UIImage alloc] initWithContentsOfFile:path];
		
		if( !tmpImage ) {
			NSLog(@"Error Loading image %@ - not found.", path);
			return NULL;
		}
		
		pixels = [self loadPixelsFromUIImage:tmpImage];
		[tmpImage release];
	}
	
	return pixels;
}

- (NSMutableData *)loadPixelsFromUIImage:(UIImage *)image {
	CGImageRef cgImage = image.CGImage;
	
	width = CGImageGetWidth(cgImage);
	height = CGImageGetHeight(cgImage);
	dimensionsKnown = true;
	
	NSMutableData *pixels = [NSMutableData dataWithLength:width*height*4];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixels.mutableBytes, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), cgImage);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	return pixels;
}

- (GLint)getParam:(GLenum)pname {
	if(pname == GL_TEXTURE_MIN_FILTER) return params[kEJTextureParamMinFilter];
	if(pname == GL_TEXTURE_MAG_FILTER) return params[kEJTextureParamMagFilter];
	if(pname == GL_TEXTURE_WRAP_S) return params[kEJTextureParamWrapS];
	if(pname == GL_TEXTURE_WRAP_T) return params[kEJTextureParamWrapT];
	return 0;
}

- (void)setParam:(GLenum)pname param:(GLenum)param {
	if(pname == GL_TEXTURE_MIN_FILTER) params[kEJTextureParamMinFilter] = param;
	else if(pname == GL_TEXTURE_MAG_FILTER) params[kEJTextureParamMagFilter] = param;
	else if(pname == GL_TEXTURE_WRAP_S) params[kEJTextureParamWrapS] = param;
	else if(pname == GL_TEXTURE_WRAP_T) params[kEJTextureParamWrapT] = param;
}

- (void)bindWithFilter:(GLenum)filter {
	params[kEJTextureParamMinFilter] = filter;
	params[kEJTextureParamMagFilter] = filter;
	[textureStorage bindToTarget:GL_TEXTURE_2D withParams:params];
}

- (void)bindToTarget:(GLenum)target {
	EJ_ENSURE_LAZY_LOADED_STORAGE();
	[textureStorage bindToTarget:target withParams:params];
}

- (UIImage *)image {
	return [EJTexture imageWithPixels:self.pixels width:width height:height scale:contentScale];
}

+ (UIImage *)imageWithPixels:(NSData *)pixels width:(int)width height:(int)height scale:(float)scale {
	UIImage *newImage = nil;
	
	int nrOfColorComponents = 4; // RGBA
	int bitsPerColorComponent = 8;
	BOOL interpolateAndSmoothPixels = NO;
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

	CGDataProviderRef dataProviderRef;
	CGColorSpaceRef colorSpaceRef;
	CGImageRef imageRef;

	@try {
		dataProviderRef = CGDataProviderCreateWithData(NULL, pixels.bytes, pixels.length, nil);
		colorSpaceRef = CGColorSpaceCreateDeviceRGB();
		imageRef = CGImageCreate(
			width, height,
			bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents,
			colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent
		);
		newImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
	}
	@finally {
		CGDataProviderRelease(dataProviderRef);
		CGColorSpaceRelease(colorSpaceRef);
		CGImageRelease(imageRef);
	}

	return newImage;
}

+ (void)premultiplyPixels:(const GLubyte *)inPixels to:(GLubyte *)outPixels byteLength:(int)byteLength format:(GLenum)format {
	const GLubyte *premultiplyTable = EJSharedTextureCache.instance.premultiplyTable.bytes;
	
	if( format == GL_RGBA ) {
		for( int i = 0; i < byteLength; i += 4 ) {
			unsigned short a = inPixels[i+3] * 256;
			outPixels[i+0] = premultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = premultiplyTable[ a + inPixels[i+1] ];
			outPixels[i+2] = premultiplyTable[ a + inPixels[i+2] ];
			outPixels[i+3] = inPixels[i+3];
		}
	}
	else if ( format == GL_LUMINANCE_ALPHA ) {		
		for( int i = 0; i < byteLength; i += 2 ) {
			unsigned short a = inPixels[i+1] * 256;
			outPixels[i+0] = premultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = inPixels[i+1];
		}
	}
}

+ (void)unPremultiplyPixels:(const GLubyte *)inPixels to:(GLubyte *)outPixels byteLength:(int)byteLength format:(GLenum)format {
	const GLubyte *unPremultiplyTable = EJSharedTextureCache.instance.unPremultiplyTable.bytes;
	
	if( format == GL_RGBA ) {
		for( int i = 0; i < byteLength; i += 4 ) {
			unsigned short a = inPixels[i+3] * 256;
			outPixels[i+0] = unPremultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = unPremultiplyTable[ a + inPixels[i+1] ];
			outPixels[i+2] = unPremultiplyTable[ a + inPixels[i+2] ];
			outPixels[i+3] = inPixels[i+3];
		}
	}
	else if ( format == GL_LUMINANCE_ALPHA ) {		
		for( int i = 0; i < byteLength; i += 2 ) {
			unsigned short a = inPixels[i+1] * 256;
			outPixels[i+0] = unPremultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = inPixels[i+1];
		}
	}
}

+ (void)flipPixelsY:(GLubyte *)pixels bytesPerRow:(int)bytesPerRow rows:(int)rows {
	if( !pixels ) { return; }
	
	GLuint middle = rows/2;
	GLuint intsPerRow = bytesPerRow / sizeof(GLuint);
	GLuint remainingBytes = bytesPerRow - intsPerRow * sizeof(GLuint);
	
	for( GLuint rowTop = 0, rowBottom = rows-1; rowTop < middle; rowTop++, rowBottom-- ) {
		
		// Swap bytes in packs of sizeof(GLuint) bytes
		GLuint *iTop = (GLuint *)(pixels + rowTop * bytesPerRow);
		GLuint *iBottom = (GLuint *)(pixels + rowBottom * bytesPerRow);
		
		GLuint itmp;
		GLint n = intsPerRow;
		do {
			itmp = *iTop;
			*iTop++ = *iBottom;
			*iBottom++ = itmp;
		} while(--n > 0);
		
		// Swap the remaining bytes
		GLubyte *bTop = (GLubyte *)iTop;
		GLubyte *bBottom = (GLubyte *)iBottom;
		
		GLubyte btmp;
		switch( remainingBytes ) {
			case 3: btmp = *bTop; *bTop++ = *bBottom; *bBottom++ = btmp;
			case 2: btmp = *bTop; *bTop++ = *bBottom; *bBottom++ = btmp;
			case 1: btmp = *bTop; *bTop = *bBottom; *bBottom = btmp;
		}
	}
}


@end
