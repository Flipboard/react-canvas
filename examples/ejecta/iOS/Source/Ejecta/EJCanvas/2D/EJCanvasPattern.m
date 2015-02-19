#import "EJCanvasPattern.h"

@implementation EJCanvasPattern

@synthesize texture;
@synthesize repeat;

- (id)initWithTexture:(EJTexture *)texturep repeat:(EJCanvasPatternRepeat)repeatp {
	if( self = [super init] ) {
		texture = texturep.copy;
		repeat = repeatp;
	}
	return self;
}

- (void)dealloc {
	[texture release];
	[super dealloc];
}

@end
