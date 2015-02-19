#import <QuartzCore/QuartzCore.h>
#import "EJCanvasContext2DScreen.h"
#import "EJJavaScriptView.h"
#import "EJJavaScriptView.h"

@implementation EJCanvasContext2DScreen
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
	
	width = newWidth;
	height = newHeight;
	
	
	CGRect frame = self.frame;
	
	float contentScale = useRetinaResolution ? UIScreen.mainScreen.scale : 1;
	backingStoreRatio = (frame.size.width / (float)width) * contentScale;
	
	bufferWidth = frame.size.width * contentScale;
	bufferHeight = frame.size.height * contentScale;
	
	NSLog(
		@"Creating ScreenCanvas (2D): "
			@"size: %dx%d, "
			@"style: %.0fx%.0f, "
			@"retina: %@ = %.0fx%.0f, "
			@"msaa: %@",
		width, height, 
		frame.size.width, frame.size.height,
		(useRetinaResolution ? @"yes" : @"no"),
		frame.size.width * contentScale, frame.size.height * contentScale,
		(msaaEnabled ? [NSString stringWithFormat:@"yes (%d samples)", msaaSamples] : @"no")
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
	}
	
	// Set up the renderbuffer
	[glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)glview.layer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);
	
	// Flip the screen - OpenGL has the origin in the bottom left corner. We want the top left.
	upsideDown = true;
	
	[super resetFramebuffer];
}

- (void)finish {
	glFinish();
}

- (void)present {
	[self flushBuffers];
	
	if( !needsPresenting ) { return; }
	
	if( msaaEnabled ) {
		//Bind the MSAA and View frameBuffers and resolve
		glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFrameBuffer);
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, viewFrameBuffer);
		glResolveMultisampleFramebufferAPPLE();
		
		glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
		[glContext presentRenderbuffer:GL_RENDERBUFFER];
		glBindFramebuffer(GL_FRAMEBUFFER, msaaFrameBuffer);
	}
	else {
		[glContext presentRenderbuffer:GL_RENDERBUFFER];
	}
	needsPresenting = NO;
}

- (EJTexture *)texture {
	// This context may not be the current one, but it has to be in order for
	// glReadPixels to succeed.
	EJCanvasContext *previousContext = scriptView.currentRenderingContext;
	scriptView.currentRenderingContext = self;

	float w = width * backingStoreRatio;
	float h = height * backingStoreRatio;
	
	EJTexture *texture = [self getImageDataScaled:1 flipped:upsideDown sx:0 sy:0 sw:w sh:h].texture;
	texture.contentScale = backingStoreRatio;
	
	scriptView.currentRenderingContext = previousContext;
	return texture;
}

@end
