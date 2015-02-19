#import "EJCanvasGradient.h"
#import "EJAppViewController.h"

@implementation EJCanvasGradient

@synthesize type;
@synthesize p1, p2, r1, r2;

- (id)initLinearGradientWithP1:(EJVector2)p1p p2:(EJVector2)p2p {
	if( self = [super init] ) {
		type = kEJCanvasGradientTypeLinear;
		p1 = p1p;
		p2 = p2p;
		
		colorStops = [[NSMutableArray alloc] initWithCapacity:4];
	}
	return self;
}

- (id)initRadialGradientWithP1:(EJVector2)p1p r1:(float)r1p p2:(EJVector2)p2p r2:(float)r2p {
	if( self = [super init] ) {
		type = kEJCanvasGradientTypeRadial;
		p1 = p1p;
		r1 = r1p;
		p2 = p2p;
		r2 = r2p;
		
		colorStops = [[NSMutableArray alloc] initWithCapacity:4];
	}
	return self;
}

- (void)dealloc {
	[texture release];
	[colorStops release];
	[super dealloc];
}

- (void)addStopWithColor:(EJColorRGBA)color at:(float)pos {
	float alpha = (float)color.rgba.a/255.0;
	EJColorRGBA premultiplied = { .rgba = {
		.r = (float)color.rgba.r * alpha,
		.g = (float)color.rgba.g * alpha,
		.b = (float)color.rgba.b * alpha,
		.a = color.rgba.a
	}};
	
	EJCanvasGradientColorStop stop = { .pos = pos, .color = premultiplied, .order = (unsigned int)colorStops.count };
	[colorStops addObject:[NSValue value:&stop withObjCType:@encode(EJCanvasGradientColorStop)]];
	
	// Release current texture; it's invalid now
	[texture release];
	texture = NULL;
}

- (EJTexture *)texture {
	if( !texture ) {
		[self rebuild];
	}
	
	return texture;
}

- (void)rebuild {
	// Sort color stops by positions. If two ore more stops are at the same
	// position, ensure that the one added last (.order) will be on top
	NSArray *sortedStops = [colorStops sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
		EJCanvasGradientColorStop s1, s2;
		[a getValue:&s1];
		[b getValue:&s2];
		
		return (s1.pos == s2.pos) ? (s1.order - s2.order) : (s1.pos - s2.pos);
	}];
	
	NSData *pixels = [self getPixelsWithWidth:EJ_CANVAS_GRADIENT_WIDTH forSortedStops:sortedStops];
	
	// Create or update Texture
	if( !texture ) {
		texture = [[EJTexture alloc] initWithWidth:EJ_CANVAS_GRADIENT_WIDTH height:1 pixels:pixels];
	}
	else {
		[texture updateWithPixels:pixels atX:0 y:0 width:EJ_CANVAS_GRADIENT_WIDTH height:1];
	}
}

- (NSData *)getPixelsWithWidth:(int)width forSortedStops:(NSArray *)stops {
	
	int byteSize = width * 4;
	NSMutableData *pixels = [NSMutableData dataWithLength:byteSize];
	
	if( !stops || !stops.count ) {
		// No stops? return empty pixel data
		return pixels;
	}
	
	EJCanvasGradientColorStop firstStop, currentStop, nextStop;
	[stops[0] getValue:&firstStop];
	currentStop = firstStop;
	
	GLubyte *bytes = pixels.mutableBytes;
	int index = 0;
	
	for( NSValue *v in stops ) {
		[v getValue:&nextStop];
		
		int stopIndex = MIN(nextStop.pos * (float)byteSize, byteSize);
		float length = (stopIndex - index)/4;
		
		// Keep the currentColor around as float values, so we can use
		// a float increment for each step.
		float currentColor[4] = {
			currentStop.color.rgba.r,
			currentStop.color.rgba.g,
			currentStop.color.rgba.b,
			currentStop.color.rgba.a,
		};

		float colorIncrement[4] = {
			(float)(nextStop.color.rgba.r - currentStop.color.rgba.r)/length,
			(float)(nextStop.color.rgba.g - currentStop.color.rgba.g)/length,
			(float)(nextStop.color.rgba.b - currentStop.color.rgba.b)/length,
			(float)(nextStop.color.rgba.a - currentStop.color.rgba.a)/length
		};
		
		for( ; index < stopIndex; index += 4 ) {
			bytes[index] = currentColor[0];
			bytes[index+1] = currentColor[1];
			bytes[index+2] = currentColor[2];
			bytes[index+3] = currentColor[3];
			
			currentColor[0] += colorIncrement[0];
			currentColor[1] += colorIncrement[1];
			currentColor[2] += colorIncrement[2];
			currentColor[3] += colorIncrement[3];
		}
		
		// Exit if we are at the end already, but set the color at the stopIndex to the
		// actual stop color; this avoids rounding errors with the colorIncrement
		if( index == byteSize ) {
			*(EJColorRGBA*)&bytes[byteSize-4] = nextStop.color;
			break;
		}
		
		currentStop = nextStop;
	}
	
	// Fill the remaining pixels if the last stop was not at 1.0
	for( ; index < byteSize; index += 4 ) {
		*(EJColorRGBA*)&bytes[index] = nextStop.color;
	}
	
	return pixels;
}

@end
