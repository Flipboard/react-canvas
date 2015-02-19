#import "EJCanvasContext2DTexture.h"
#import "EJJavaScriptView.h"

@implementation EJCanvasContext2DTexture

- (void)dealloc {
	[texture release];
	[super dealloc];
}

- (void)resizeToWidth:(short)newWidth height:(short)newHeight {
	[self flushBuffers];
	
	width = newWidth;
	height = newHeight;
	
	backingStoreRatio = (useRetinaResolution && [UIScreen mainScreen].scale == 2) ? 2 : 1;
	bufferWidth = width * backingStoreRatio;
	bufferHeight = height * backingStoreRatio;
	
	NSLog(
		@"Creating Offscreen Canvas (2D): "
			@"size: %dx%d, "
			@"retina: %@ = %.0fx%.0f, "
			@"msaa: %@",
		width, height,
		(useRetinaResolution ? @"yes" : @"no"),
		width * backingStoreRatio, height * backingStoreRatio,
		(msaaEnabled ? [NSString stringWithFormat:@"yes (%d samples)", msaaSamples] : @"no")
	);
	
	// Release previous texture if any, create the new texture and set it as
	// the rendering target for this framebuffer
	[texture release];
	texture = [[EJTexture alloc] initAsRenderTargetWithWidth:newWidth height:newHeight
		fbo:viewFrameBuffer contentScale:backingStoreRatio];
	
	glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture.textureId, 0);
	
	[self resetFramebuffer];
}

- (EJTexture *)texture {
	// If this texture Canvas uses MSAA, we need to resolve the MSAA first,
	// before we can use the texture for drawing.
	if( msaaEnabled && needsPresenting ) {
		GLint boundFrameBuffer;
		glGetIntegerv( GL_FRAMEBUFFER_BINDING, &boundFrameBuffer );
		
		//Bind the MSAA and View frameBuffers and resolve
		glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFrameBuffer);
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, viewFrameBuffer);
		glResolveMultisampleFramebufferAPPLE();
		
		glBindFramebuffer(GL_FRAMEBUFFER, boundFrameBuffer);
		needsPresenting = NO;
	}
	
	// Special case where this canvas is drawn into itself - we have to use glReadPixels to get a texture
	if( scriptView.currentRenderingContext == self ) {	
		float w = width * backingStoreRatio;
		float h = height * backingStoreRatio;
		
		EJTexture *tempTexture = [self getImageDataScaled:1 flipped:upsideDown sx:0 sy:0 sw:w sh:h].texture;
		tempTexture.contentScale = backingStoreRatio;
		return tempTexture;
	}
	
	// Just use the framebuffer texture directly
	else {
		return texture;
	}
}

@end
