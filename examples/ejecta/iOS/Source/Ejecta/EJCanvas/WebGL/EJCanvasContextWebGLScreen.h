#import "EJCanvasContextWebGL.h"
#import "EAGLView.h"
#import "EJPresentable.h"

@interface EJCanvasContextWebGLScreen : EJCanvasContextWebGL <EJPresentable> {
	EAGLView *glview;
	CGRect style;
}

- (void)present;
- (void)finish;

@end
