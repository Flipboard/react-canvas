#import "EJImageData.h"

@implementation EJImageData

@synthesize width, height, pixels;

- (id)initWithWidth:(int)widthp height:(int)heightp pixels:(NSMutableData *)pixelsp {
	if( self = [super init] ) {
		width = widthp;
		height = heightp;
		pixels = [pixelsp retain];
	}
	return self;
}

- (void)dealloc {
	[pixels release];
	[super dealloc];
}

- (EJTexture *)texture {
	return [[[EJTexture alloc] initWithWidth:width height:height pixels:pixels] autorelease];
}

@end
