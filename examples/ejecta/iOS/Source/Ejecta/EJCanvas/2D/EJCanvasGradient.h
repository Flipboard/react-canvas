#import <Foundation/Foundation.h>
#import "EJCanvas2DTypes.h"
#import "EJCanvasContext2D.h"
#import "EJTexture.h"

#define EJ_CANVAS_GRADIENT_WIDTH 1024

typedef enum {
	kEJCanvasGradientTypeLinear,
	kEJCanvasGradientTypeRadial
} EJCanvasGradientType;

typedef struct {
	float pos;
	unsigned int order;
	EJColorRGBA color;
} EJCanvasGradientColorStop;

@interface EJCanvasGradient : NSObject <EJFillable> {
	EJCanvasGradientType type;
	EJVector2 p1, p2;
	float r1, r2;
	
	NSMutableArray *colorStops;
	EJTexture *texture;
}

- (id)initLinearGradientWithP1:(EJVector2)p1 p2:(EJVector2)p2;
- (id)initRadialGradientWithP1:(EJVector2)p1 r1:(float)r1 p2:(EJVector2)p2 r2:(float)r2;

- (void)addStopWithColor:(EJColorRGBA)color at:(float)pos;
- (void)rebuild;
- (NSData *)getPixelsWithWidth:(int)width forSortedStops:(NSArray *)stops;

@property (readonly, nonatomic) EJCanvasGradientType type;
@property (readonly, nonatomic) EJTexture *texture;
@property (readonly, nonatomic) EJVector2 p1;
@property (readonly, nonatomic) EJVector2 p2;
@property (readonly, nonatomic) float r1;
@property (readonly, nonatomic) float r2;

@end
