#import "EJBindingImageData.h"
#import "EJJavaScriptView.h"
#import <JavaScriptCore/JSTypedArray.h>

@implementation EJBindingImageData
@synthesize imageData;

- (id)initWithImageData:(EJImageData *)data {
	if( self = [super initWithContext:NULL argc:0 argv:NULL] ) {
		imageData = [data retain];
		dataArray = NULL;
	}
	return self;
}

- (void)dealloc {
	if( dataArray ) {
		JSValueUnprotectSafe(scriptView.jsGlobalContext, dataArray);
	}
	
	[imageData release];
	[super dealloc];
}

- (EJImageData *)imageData {
	if( dataArray ) {
		// Copy values from the JSArray back into the imageData and premultiply it
		int byteLength = imageData.width * imageData.height * 4;
		
		[EJTexture
			premultiplyPixels:JSTypedArrayGetDataPtr(scriptView.jsGlobalContext, dataArray, NULL)
			to:imageData.pixels.mutableBytes
			byteLength:byteLength format:GL_RGBA];
	}
	
	return imageData;
}

- (EJTexture *)texture {
	return imageData.texture;
}

EJ_BIND_GET(data, ctx ) {
	if( !dataArray ) {
		// Copy values from image data into a JSArray and unpremultiply it
		int byteLength = imageData.width * imageData.height * 4;
		
		dataArray = JSTypedArrayMake(ctx, kJSTypedArrayTypeUint8ClampedArray, byteLength);
		JSValueProtect(ctx, dataArray);
		
		[EJTexture
			unPremultiplyPixels:imageData.pixels.bytes
			to:JSTypedArrayGetDataPtr(ctx, dataArray, NULL)
			byteLength:byteLength format:GL_RGBA];
	}
	return dataArray;
}

EJ_BIND_GET(width, ctx ) {
	return JSValueMakeNumber( ctx, imageData.width);
}

EJ_BIND_GET(height, ctx ) { 
	return JSValueMakeNumber( ctx, imageData.height );
}

@end
