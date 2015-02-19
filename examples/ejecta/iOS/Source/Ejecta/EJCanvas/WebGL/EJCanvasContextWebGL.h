#import "EJCanvasContext.h"

@class EJJavaScriptView;
@interface EJCanvasContextWebGL : EJCanvasContext {
	GLuint viewFrameBuffer, viewRenderBuffer;
	GLuint depthStencilBuffer;
	
	GLuint boundFramebuffer;
	GLuint boundRenderbuffer;
	
	GLint bufferWidth, bufferHeight;
	EJJavaScriptView *scriptView;
}

- (id)initWithScriptView:(EJJavaScriptView *)scriptView width:(short)width height:(short)height;
- (void)bindRenderbuffer;
- (void)bindFramebuffer;
- (void)create;
- (void)prepare;
- (void)clear;

@property (nonatomic) BOOL needsPresenting;
@property (nonatomic) GLuint boundFramebuffer;
@property (nonatomic) GLuint boundRenderbuffer;

@end
