#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "EJTextureStorage.h"

@interface EJTexture : NSObject <NSCopying> {
	BOOL cached;
	BOOL drawFlippedY;
	BOOL isCompressed;
	BOOL lazyLoaded;
	BOOL dimensionsKnown;
	short width, height;
	NSString *fullPath;
	EJTextureStorage *textureStorage;
	GLenum format;
	GLuint fbo;
	float contentScale;
	
	EJTextureParams params;
	NSBlockOperation *loadCallback;
}
- (id)initEmptyForWebGL;
- (id)initWithPath:(NSString *)path;
+ (id)cachedTextureWithPath:(NSString *)path loadOnQueue:(NSOperationQueue *)queue callback:(NSOperation *)callback;
- (id)initWithPath:(NSString *)path loadOnQueue:(NSOperationQueue *)queue callback:(NSOperation *)callback;

- (id)initWithWidth:(int)widthp height:(int)heightp;
- (id)initWithWidth:(int)widthp height:(int)heightp format:(GLenum) format;
- (id)initWithWidth:(int)widthp height:(int)heightp pixels:(NSData *)pixels;
- (id)initAsRenderTargetWithWidth:(int)widthp height:(int)heightp fbo:(GLuint)fbo contentScale:(float)contentScalep;
- (id)initWithUIImage:(UIImage *)image;

- (void)maybeReleaseStorage;

- (void)ensureMutableKeepPixels:(BOOL)keepPixels forTarget:(GLenum)target;

- (void)createWithTexture:(EJTexture *)other;
- (void)createWithPixels:(NSData *)pixels format:(GLenum)format;
- (void)createWithPixels:(NSData *)pixels format:(GLenum)formatp target:(GLenum)target;
- (void)uploadCompressedPixels:(NSData *)pixels target:(GLenum)target;
- (void)updateWithPixels:(NSData *)pixels atX:(int)x y:(int)y width:(int)subWidth height:(int)subHeight;

- (NSMutableData *)loadPixelsFromPath:(NSString *)path;
- (NSMutableData *)loadPixelsFromUIImage:(UIImage *)image;

- (GLint)getParam:(GLenum)pname;
- (void)setParam:(GLenum)pname param:(GLenum)param;

- (void)bindWithFilter:(GLenum)filter;
- (void)bindToTarget:(GLenum)target;

- (UIImage *)image;
+ (UIImage *)imageWithPixels:(NSData *)pixels width:(int)width height:(int)height scale:(float)scale;

+ (void)premultiplyPixels:(const GLubyte *)inPixels to:(GLubyte *)outPixels byteLength:(int)byteLength format:(GLenum)format;
+ (void)unPremultiplyPixels:(const GLubyte *)inPixels to:(GLubyte *)outPixels byteLength:(int)byteLength format:(GLenum)format;
+ (void)flipPixelsY:(GLubyte *)pixels bytesPerRow:(int)bytesPerRow rows:(int)rows;

@property (readwrite, nonatomic) BOOL drawFlippedY;
@property (readonly, nonatomic) BOOL isDynamic;
@property (readonly, nonatomic) BOOL lazyLoaded;
@property (readonly, nonatomic) NSMutableData *pixels;
@property (readwrite, nonatomic) float contentScale;
@property (readonly, nonatomic) GLuint textureId;
@property (readonly, nonatomic) GLenum format;
@property (readonly, nonatomic) short width, height;
@property (readonly, nonatomic) NSTimeInterval lastUsed;

@end
