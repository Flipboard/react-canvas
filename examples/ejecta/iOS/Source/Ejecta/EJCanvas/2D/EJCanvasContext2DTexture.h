#import "EJCanvasContext2D.h"

@interface EJCanvasContext2DTexture : EJCanvasContext2D {
	EJTexture *texture;
}

@property (readonly, nonatomic) EJTexture *texture;

@end
