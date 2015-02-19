#import "EJCanvasContextWebGLScreen.h"

@implementation EJCanvasContextWebGLScreen
@synthesize style;

- (void)dealloc {
	[glview removeFromSuperview];
	[glview release];
	[super dealloc];
}

- (void)setStyle:(CGRect)newStyle {
	if(
		(style.size.width ? style.size.width : width) != newStyle.size.width ||
		(style.size.height ? style.size.height : height) != newStyle.size.height
	) {
		// Must resize
		style = newStyle;
		[self resizeToWidth:width height:height];
	}
	else {
		// Just reposition
		style = newStyle;
		if( glview ) {
			glview.frame = self.frame;
		}
	}
}

- (CGRect)frame {
	// Returns the view frame with the current style. If the style's witdth/height
	// is zero, the canvas width/height is used
	return CGRectMake(
		style.origin.x,
		style.origin.y,
		(style.size.width ? style.size.width : width),
		(style.size.height ? style.size.height : height)
	);
}

- (void)resizeToWidth:(short)newWidth height:(short)newHeight {
	[self flushBuffers];
	
	bufferWidth = width = newWidth;
	bufferHeight = height = newHeight;
	
	CGRect frame = self.frame;
	float contentScale = bufferWidth / frame.size.width;
	
	NSLog(
		@"Creating ScreenCanvas (WebGL): "
			@"size: %dx%d, "
			@"style: %.0fx%.0f",
		width, height, 
		frame.size.width, frame.size.height
	);
	
	if( !glview ) {
		// Create the OpenGL UIView with final screen size and content scaling (retina)
		glview = [[EAGLView alloc] initWithFrame:frame contentScale:contentScale retainedBacking:YES];
		
		// Append the OpenGL view to Ejecta's main view
		[scriptView addSubview:glview];
	}
	else {
		// Resize an existing view
		glview.frame = frame;
		glview.contentScaleFactor = contentScale;
		glview.layer.contentsScale = contentScale;
	}
	
	GLint previousFrameBuffer;
	GLint previousRenderBuffer;
	glGetIntegerv( GL_FRAMEBUFFER_BINDING, &previousFrameBuffer );
	glGetIntegerv( GL_RENDERBUFFER_BINDING, &previousRenderBuffer );
	
	glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
	
	// Set up the renderbuffer and some initial OpenGL properties
	[glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)glview.layer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);
	
	// Set up the depth and stencil buffer
	glBindRenderbuffer(GL_RENDERBUFFER, depthStencilBuffer);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, bufferWidth, bufferHeight);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthStencilBuffer);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depthStencilBuffer);
	
	// Clear
	glViewport(0, 0, width, height);
	[self clear];
	
	// Reset to the previously bound frame and renderbuffers
	glBindFramebuffer(GL_FRAMEBUFFER, previousFrameBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, previousRenderBuffer);
}

- (void)finish {
	glFinish();
}

- (void)present {
	if( !needsPresenting ) { return; }
	
	[glContext presentRenderbuffer:GL_RENDERBUFFER];
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	needsPresenting = NO;
}

@end
