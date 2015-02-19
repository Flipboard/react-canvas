#import "EJCanvasContext2D.h"
#import "EJFont.h"
#import "EJJavaScriptView.h"

#import "EJCanvasPattern.h"
#import "EJCanvasGradient.h"

@implementation EJCanvasContext2D

const EJCompositeOperationFunc EJCompositeOperationFuncs[] = {
	[kEJCompositeOperationSourceOver] = {GL_ONE, GL_ONE_MINUS_SRC_ALPHA, 1},
	[kEJCompositeOperationLighter] = {GL_ONE, GL_ONE_MINUS_SRC_ALPHA, 0},
	[kEJCompositeOperationDarker] = {GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA, 1},
	[kEJCompositeOperationDestinationOut] = {GL_ZERO, GL_ONE_MINUS_SRC_ALPHA, 1},
	[kEJCompositeOperationDestinationOver] = {GL_ONE_MINUS_DST_ALPHA, GL_ONE, 1},
	[kEJCompositeOperationSourceAtop] = {GL_DST_ALPHA, GL_ONE_MINUS_SRC_ALPHA, 1},
	[kEJCompositeOperationXOR] = {GL_ONE_MINUS_DST_ALPHA, GL_ONE_MINUS_SRC_ALPHA, 1},
	[kEJCompositeOperationCopy] = {GL_ONE, GL_ZERO, 1},
	[kEJCompositeOperationSourceIn] = {GL_DST_ALPHA, GL_ZERO, 1},
	[kEJCompositeOperationDestinationIn] = {GL_ZERO, GL_SRC_ALPHA, 1},
	[kEJCompositeOperationSourceOut] = {GL_ONE_MINUS_DST_ALPHA, GL_ZERO, 1},
	[kEJCompositeOperationDestinationAtop] = {GL_ONE_MINUS_DST_ALPHA, GL_SRC_ALPHA, 1}
};


@synthesize state;
@synthesize imageSmoothingEnabled;
@synthesize stencilMask;

- (id)initWithScriptView:(EJJavaScriptView *)scriptViewp width:(short)widthp height:(short)heightp {
	if( self = [super init] ) {
		scriptView = scriptViewp;
		sharedGLContext = scriptView.openGLContext;
		glContext = sharedGLContext.glContext2D;
		vertexBuffer = (EJVertex *)(sharedGLContext.vertexBuffer.mutableBytes);
		vertexBufferSize = (int)(sharedGLContext.vertexBuffer.length / sizeof(EJVertex));
	
		memset(stateStack, 0, sizeof(stateStack));
		stateIndex = 0;
		state = &stateStack[stateIndex];
		state->globalAlpha = 1;
		state->globalCompositeOperation = kEJCompositeOperationSourceOver;
		state->transform = CGAffineTransformIdentity;
		state->lineWidth = 1;
		state->lineCap = kEJLineCapButt;
		state->lineJoin = kEJLineJoinMiter;
		state->miterLimit = 10;
		state->textBaseline = kEJTextBaselineAlphabetic;
		state->textAlign = kEJTextAlignStart;
		state->font = [[EJFontDescriptor descriptorWithName:@"Helvetica" size:10] retain];
		state->clipPath = nil;
		
		bufferWidth = width = widthp;
		bufferHeight = height = heightp;
		
		path = [[EJPath alloc] init];
		backingStoreRatio = 1;
		
		fontCache = [[EJFontCache instance] retain];
		
		textureFilter = GL_LINEAR;
		msaaEnabled = NO;
		msaaSamples = 2;
		stencilMask = 0x1;
	}
	return self;
}

- (void)dealloc {
	// Make sure this rendering context is the current one, so all
	// OpenGL objects can be deleted properly.
	EAGLContext *oldContext = [EAGLContext currentContext];
	[EAGLContext setCurrentContext:glContext];
	
	[fontCache release];
	
	// Release all fonts, clip paths and patterns from the stack
	for( int i = 0; i < stateIndex + 1; i++ ) {
		[stateStack[i].font release];
		[stateStack[i].clipPath release];
		[stateStack[i].fillObject release];
		[stateStack[i].strokeObject release];
	}
	
	if( viewFrameBuffer ) { glDeleteFramebuffers( 1, &viewFrameBuffer); }
	if( viewRenderBuffer ) { glDeleteRenderbuffers(1, &viewRenderBuffer); }
	if( msaaFrameBuffer ) {	glDeleteFramebuffers( 1, &msaaFrameBuffer); }
	if( msaaRenderBuffer ) { glDeleteRenderbuffers(1, &msaaRenderBuffer); }
	if( stencilBuffer ) { glDeleteRenderbuffers(1, &stencilBuffer); }
	
	[path release];
	[EAGLContext setCurrentContext:oldContext];
	
	[super dealloc];
}

- (void)create {
	if( msaaEnabled ) {
		glGenFramebuffers(1, &msaaFrameBuffer);
		glGenRenderbuffers(1, &msaaRenderBuffer);
	}
	
	glGenFramebuffers(1, &viewFrameBuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
	
	glGenRenderbuffers(1, &viewRenderBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
	
	glDisable(GL_CULL_FACE);
	glDisable(GL_DITHER);
	
	glEnable(GL_BLEND);
	glDepthFunc(GL_ALWAYS);
	
	[self resizeToWidth:width height:height];
}

- (void)resizeToWidth:(short)newWidth height:(short)newHeight {
	// This function is a stub - Overwritten in both subclasses
	width = newWidth;
	height = newHeight;
	
	backingStoreRatio = (useRetinaResolution && [UIScreen mainScreen].scale == 2) ? 2 : 1;
	bufferWidth = width * backingStoreRatio;
	bufferHeight = height * backingStoreRatio;
	
	[self resetFramebuffer];
}

- (void)resetFramebuffer {
	// Delete stencil buffer if present; it will be re-created when needed
	if( stencilBuffer ) {
		glDeleteRenderbuffers(1, &stencilBuffer);
		stencilBuffer = 0;
	}
	
	// Resize the MSAA buffer
	if( msaaEnabled && msaaFrameBuffer && msaaRenderBuffer ) {
		glBindFramebuffer(GL_FRAMEBUFFER, msaaFrameBuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderBuffer);
		
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, msaaSamples, GL_RGBA8_OES, bufferWidth, bufferHeight);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, msaaRenderBuffer);
	}
	
	[self prepare];
	
	// Clear to transparent
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	
	needsPresenting = YES;
}

- (void)createStencilBufferOnce {
	if( stencilBuffer ) { return; }
	
	glGenRenderbuffers(1, &stencilBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, stencilBuffer);
	if( msaaEnabled ) {
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, msaaSamples, GL_DEPTH24_STENCIL8_OES, bufferWidth, bufferHeight);
	}
	else {
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, bufferWidth, bufferHeight);
	}
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, stencilBuffer);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, stencilBuffer);
	
	glBindRenderbuffer(GL_RENDERBUFFER, msaaEnabled ? msaaRenderBuffer : viewRenderBuffer );
	
	glClear(GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
}

- (void)bindVertexBuffer {	
	glEnableVertexAttribArray(kEJGLProgram2DAttributePos);
	glVertexAttribPointer(kEJGLProgram2DAttributePos, 2, GL_FLOAT, GL_FALSE,
		sizeof(EJVertex), (char *)vertexBuffer + offsetof(EJVertex, pos));
	
	glEnableVertexAttribArray(kEJGLProgram2DAttributeUV);
	glVertexAttribPointer(kEJGLProgram2DAttributeUV, 2, GL_FLOAT, GL_FALSE,
		sizeof(EJVertex), (char *)vertexBuffer + offsetof(EJVertex, uv));

	glEnableVertexAttribArray(kEJGLProgram2DAttributeColor);
	glVertexAttribPointer(kEJGLProgram2DAttributeColor, 4, GL_UNSIGNED_BYTE, GL_TRUE,
		sizeof(EJVertex), (char *)vertexBuffer + offsetof(EJVertex, color));
}

- (void)prepare {
	// Bind the frameBuffer and vertexBuffer array
	glBindFramebuffer(GL_FRAMEBUFFER, msaaEnabled ? msaaFrameBuffer : viewFrameBuffer );
	glBindRenderbuffer(GL_RENDERBUFFER, msaaEnabled ? msaaRenderBuffer : viewRenderBuffer );
	
	glViewport(0, 0, bufferWidth, bufferHeight);
	
	EJCompositeOperation op = state->globalCompositeOperation;
	glBlendFunc( EJCompositeOperationFuncs[op].source, EJCompositeOperationFuncs[op].destination );
	currentTexture = nil;
	currentProgram = nil;
	
	[self bindVertexBuffer];
	
	if( stencilBuffer ) {
		glEnable(GL_DEPTH_TEST);
	}
	else {
		glDisable(GL_DEPTH_TEST);
	}
	
	if( state->clipPath ) {
		glDepthFunc(GL_EQUAL);
	}
	else {
		glDepthFunc(GL_ALWAYS);
	}
	
	needsPresenting = YES;
}

- (void)setWidth:(short)newWidth {
	if( newWidth == width ) {
		// Same width as before? Just clear the canvas, as per the spec
		[self flushBuffers];
		glClear(GL_COLOR_BUFFER_BIT);
		return;
	}
	[self resizeToWidth:newWidth height:height];
}

- (void)setHeight:(short)newHeight {
	if( newHeight == height ) {
		// Same height as before? Just clear the canvas, as per the spec
		[self flushBuffers];
		glClear(GL_COLOR_BUFFER_BIT);
		return;
	}
	[self resizeToWidth:width height:newHeight];
}

- (void)setTexture:(EJTexture *)newTexture {
	if( currentTexture == newTexture ) { return; }
	
	[self flushBuffers];
	
	currentTexture = newTexture;
	[currentTexture bindWithFilter:textureFilter];
}

- (void)setProgram:(EJGLProgram2D *)newProgram {
	if( currentProgram == newProgram ) { return; }
	
	[self flushBuffers];
	currentProgram = newProgram;
	
	glUseProgram(currentProgram.program);
	glUniform2f(currentProgram.screen, width, height * (upsideDown ? -1 : 1));
}

- (void)pushTriX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2
	x3:(float)x3 y3:(float)y3
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{
	if( vertexBufferIndex >= vertexBufferSize - 3 ) {
		[self flushBuffers];
	}
	
	EJVector2 d1 = { x1, y1 };
	EJVector2 d2 = { x2, y2 };
	EJVector2 d3 = { x3, y3 };
	
	if( !CGAffineTransformIsIdentity(transform) ) {
		d1 = EJVector2ApplyTransform( d1, transform );
		d2 = EJVector2ApplyTransform( d2, transform );
		d3 = EJVector2ApplyTransform( d3, transform );
	}
	
	EJVertex *vb = &vertexBuffer[vertexBufferIndex];
	vb[0] = (EJVertex) { d1, {0, 0}, color };
	vb[1] = (EJVertex) { d2, {0, 0}, color };
	vb[2] = (EJVertex) { d3, {0, 0}, color };
	
	vertexBufferIndex += 3;
}

- (void)pushQuadV1:(EJVector2)v1 v2:(EJVector2)v2 v3:(EJVector2)v3 v4:(EJVector2)v4
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{
	if( vertexBufferIndex >= vertexBufferSize - 6 ) {
		[self flushBuffers];
	}
	
	if( !CGAffineTransformIsIdentity(transform) ) {
		v1 = EJVector2ApplyTransform( v1, transform );
		v2 = EJVector2ApplyTransform( v2, transform );
		v3 = EJVector2ApplyTransform( v3, transform );
		v4 = EJVector2ApplyTransform( v4, transform );
	}
	
	EJVertex *vb = &vertexBuffer[vertexBufferIndex];
	vb[0] = (EJVertex) { v1, {0, 0}, color };
	vb[1] = (EJVertex) { v2, {0, 0}, color };
	vb[2] = (EJVertex) { v3, {0, 0}, color };
	vb[3] = (EJVertex) { v2, {0, 0}, color };
	vb[4] = (EJVertex) { v3, {0, 0}, color };
	vb[5] = (EJVertex) { v4, {0, 0}, color };
	
	vertexBufferIndex += 6;
}

- (void)pushRectX:(float)x y:(float)y w:(float)w h:(float)h
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{
	if( vertexBufferIndex >= vertexBufferSize - 6 ) {
		[self flushBuffers];
	}
		
	EJVector2 d11 = {x, y};
	EJVector2 d21 = {x+w, y};
	EJVector2 d12 = {x, y+h};
	EJVector2 d22 = {x+w, y+h};
	
	if( !CGAffineTransformIsIdentity(transform) ) {
		d11 = EJVector2ApplyTransform( d11, transform );
		d21 = EJVector2ApplyTransform( d21, transform );
		d12 = EJVector2ApplyTransform( d12, transform );
		d22 = EJVector2ApplyTransform( d22, transform );
	}
	
	EJVertex *vb = &vertexBuffer[vertexBufferIndex];
	vb[0] = (EJVertex) { d11, {0, 0}, color };	// top left
	vb[1] = (EJVertex) { d21, {0, 0}, color };	// top right
	vb[2] = (EJVertex) { d12, {0, 0}, color };	// bottom left
		
	vb[3] = (EJVertex) { d21, {0, 0}, color };	// top right
	vb[4] = (EJVertex) { d12, {0, 0}, color };	// bottom left
	vb[5] = (EJVertex) { d22, {0, 0}, color };	// bottom right
	
	vertexBufferIndex += 6;
}

- (void)pushFilledRectX:(float)x y:(float)y w:(float)w h:(float)h
	fillable:(NSObject<EJFillable> *)fillable
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{
	if( [fillable isKindOfClass:[EJCanvasPattern class]] ) {
		EJCanvasPattern *pattern = (EJCanvasPattern *)fillable;
		[self pushPatternedRectX:x y:y w:w h:h pattern:pattern color:color withTransform:transform];
	}
	else if( [fillable isKindOfClass:[EJCanvasGradient class]] ) {
		EJCanvasGradient *gradient = (EJCanvasGradient *)fillable;
		[self pushGradientRectX:x y:y w:w h:h gradient:gradient color:color withTransform:transform];
	}
}

- (void)pushGradientRectX:(float)x y:(float)y w:(float)w h:(float)h
	gradient:(EJCanvasGradient *)gradient
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{	
	if( gradient.type == kEJCanvasGradientTypeLinear ) {
		// Local positions inside the quad
		EJVector2 p1 = {(gradient.p1.x-x)/w, (gradient.p1.y-y)/h};
		EJVector2 p2 = {(gradient.p2.x-x)/w, (gradient.p2.y-y)/h};
		
		// Calculate the slope of (p1,p2) and the line orthogonal to it
		float aspect = w/h;
		EJVector2 slope = EJVector2Sub(p2, p1);
		EJVector2 ortho = {slope.y/aspect, -slope.x*aspect};
		
		// Calculate the intersection points of the slope (starting at p1)
		// and the orthogonal starting at each corner of the quad - these
		// points are the final texture coordinates.
		float d = 1/(slope.y * ortho.x - slope.x * ortho.y);
		
		EJVector2
			ot = {ortho.x * d, ortho.y * d},
			st = {slope.x * d, slope.y * d};
		
		EJVector2
			a11 = {ot.x * -p1.y, st.x * -p1.y},
			a12 = {ot.y * p1.x, st.y * p1.x},
			a21 = {ot.x * (1 - p1.y), st.x * (1 - p1.y)},
			a22 = {ot.y * (p1.x - 1), st.y * (p1.x - 1)};
			
		EJVector2
			t11 = {a11.x + a12.x, a11.y + a12.y},
			t21 = {a11.x + a22.x, a11.y + a22.y},
			t12 = {a21.x + a12.x, a21.y + a12.y},
			t22 = {a21.x + a22.x, a21.y + a22.y};
		
		[self setProgram:sharedGLContext.glProgram2DTexture];
		[self setTexture:gradient.texture];
		if( vertexBufferIndex >= vertexBufferSize - 6 ) {
			[self flushBuffers];
		}
		
		// Vertex coordinates
		EJVector2 d11 = {x, y};
		EJVector2 d21 = {x+w, y};
		EJVector2 d12 = {x, y+h};
		EJVector2 d22 = {x+w, y+h};
		
		if( !CGAffineTransformIsIdentity(transform) ) {
			d11 = EJVector2ApplyTransform( d11, transform );
			d21 = EJVector2ApplyTransform( d21, transform );
			d12 = EJVector2ApplyTransform( d12, transform );
			d22 = EJVector2ApplyTransform( d22, transform );
		}

		EJVertex *vb = &vertexBuffer[vertexBufferIndex];
		vb[0] = (EJVertex) { d11, t11, color };	// top left
		vb[1] = (EJVertex) { d21, t21, color };	// top right
		vb[2] = (EJVertex) { d12, t12, color };	// bottom left
			
		vb[3] = (EJVertex) { d21, t21, color };	// top right
		vb[4] = (EJVertex) { d12, t12, color };	// bottom left
		vb[5] = (EJVertex) { d22, t22, color };	// bottom right
		
		vertexBufferIndex += 6;
	}
	
	else if( gradient.type == kEJCanvasGradientTypeRadial ) {
		[self flushBuffers];
				
		EJGLProgram2DRadialGradient *gradientProgram = sharedGLContext.glProgram2DRadialGradient;
		[self setProgram:gradientProgram];
		
		glUniform3f(gradientProgram.inner, gradient.p1.x, gradient.p1.y, gradient.r1);
		EJVector2 dp = EJVector2Sub(gradient.p2, gradient.p1);
		float dr = gradient.r2 - gradient.r1;
		glUniform3f(gradientProgram.diff, dp.x, dp.y, dr);
		
		[self setTexture:gradient.texture];
		[self pushTexturedRectX:x y:y w:w h:h tx:x ty:y tw:w th:h color:color withTransform:transform];
	}
}

- (void)pushPatternedRectX:(float)x y:(float)y w:(float)w h:(float)h
	pattern:(EJCanvasPattern *)pattern
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{
	EJTexture *texture = pattern.texture;
	float scale = texture.contentScale;
	float
		tw = texture.width / scale,
		th = texture.height / scale,
		pw = w,
		ph = h;
		
	if( !(pattern.repeat & kEJCanvasPatternRepeatX) ) {
		pw = MIN(tw - x, w);
	}
	if( !(pattern.repeat & kEJCanvasPatternRepeatY) ) {
		ph = MIN(th - y, h);
	}

	if( pw > 0 && ph > 0 ) { // We may have to skip entirely
		[self setProgram:sharedGLContext.glProgram2DPattern];
		[self setTexture:texture];
		
		[self pushTexturedRectX:x y:y w:pw h:ph tx:x/tw ty:y/th tw:pw/tw th:ph/th
			color:color withTransform:transform];
	}
	
	if( pw < w || ph < h ) {
		// Draw clearing rect for the stencil buffer if we didn't fill everything with
		// the pattern image - happens when not repeating in both directions
		[self setProgram:sharedGLContext.glProgram2DFlat];
		EJColorRGBA transparentBlack = {.hex = 0x00000000};
		[self pushRectX:x y:y w:w h:h color:transparentBlack withTransform:transform];
	}
}

- (void)pushTexturedRectX:(float)x y:(float)y w:(float)w h:(float)h
	tx:(float)tx ty:(float)ty tw:(float)tw th:(float)th
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform
{
	if( vertexBufferIndex >= vertexBufferSize - 6 ) {
		[self flushBuffers];
	}
	
	// Textures from offscreen WebGL contexts have to be draw upside down.
	// They're actually right-side up in memory, but everything else has
	// flipped y
	if( currentTexture.drawFlippedY ) {
		ty = 1 - ty;
		th *= -1;
	}
	
	EJVector2 d11 = {x, y};
	EJVector2 d21 = {x+w, y};
	EJVector2 d12 = {x, y+h};
	EJVector2 d22 = {x+w, y+h};
	
	if( !CGAffineTransformIsIdentity(transform) ) {
		d11 = EJVector2ApplyTransform( d11, transform );
		d21 = EJVector2ApplyTransform( d21, transform );
		d12 = EJVector2ApplyTransform( d12, transform );
		d22 = EJVector2ApplyTransform( d22, transform );
	}

	EJVertex *vb = &vertexBuffer[vertexBufferIndex];
	vb[0] = (EJVertex) { d11, {tx, ty}, color };	// top left
	vb[1] = (EJVertex) { d21, {tx+tw, ty}, color };	// top right
	vb[2] = (EJVertex) { d12, {tx, ty+th}, color };	// bottom left
		
	vb[3] = (EJVertex) { d21, {tx+tw, ty}, color };	// top right
	vb[4] = (EJVertex) { d12, {tx, ty+th}, color };	// bottom left
	vb[5] = (EJVertex) { d22, {tx+tw, ty+th}, color };	// bottom right
	
	vertexBufferIndex += 6;
}

- (void)flushBuffers {
	if( vertexBufferIndex == 0 ) { return; }
	
	glDrawArrays(GL_TRIANGLES, 0, vertexBufferIndex);
	needsPresenting = YES;
	vertexBufferIndex = 0;
}

- (BOOL)imageSmoothingEnabled {
	return (textureFilter == GL_LINEAR);
}

- (void)setImageSmoothingEnabled:(BOOL)enabled {
	[self setTexture:NULL]; // force rebind for next texture
	textureFilter = (enabled ? GL_LINEAR : GL_NEAREST);
}

- (void)setGlobalCompositeOperation:(EJCompositeOperation)op {
	// Same composite operation or switching between SourceOver <> Lighter? We don't
	// have to flush and set the blend mode then, but we still need to update the state,
	// as the alphaFactor may be different.
	if(
		op == state->globalCompositeOperation ||
		(op == kEJCompositeOperationLighter && state->globalCompositeOperation == kEJCompositeOperationSourceOver) ||
		(op == kEJCompositeOperationSourceOver && state->globalCompositeOperation == kEJCompositeOperationLighter)
	) {
		state->globalCompositeOperation = op;
		return;
	}
	
	[self flushBuffers];
	glBlendFunc( EJCompositeOperationFuncs[op].source, EJCompositeOperationFuncs[op].destination );
	state->globalCompositeOperation = op;
}

- (EJCompositeOperation)globalCompositeOperation {
	return state->globalCompositeOperation;
}

- (void)setFont:(EJFontDescriptor *)font {
	[state->font release];
	state->font = [font retain];
}

- (EJFontDescriptor *)font {
	return state->font;
}

- (void)setFillObject:(NSObject<EJFillable> *)fillObject {
	[state->fillObject release];
	state->fillObject = [fillObject retain];
}

- (NSObject<EJFillable> *)fillObject {
	return state->fillObject;
}

- (void)setStrokeObject:(NSObject<EJFillable> *)strokeObject {
	[state->strokeObject release];
	state->strokeObject = [strokeObject retain];
}

- (NSObject<EJFillable> *)strokeObject {
	return state->strokeObject;
}


- (void)save {
	if( stateIndex == EJ_CANVAS_STATE_STACK_SIZE-1 ) {
		NSLog(@"Warning: EJ_CANVAS_STATE_STACK_SIZE (%d) reached", EJ_CANVAS_STATE_STACK_SIZE);
		return;
	}
	
	stateStack[stateIndex+1] = stateStack[stateIndex];
	stateIndex++;
	state = &stateStack[stateIndex];
	[state->font retain];
	[state->fillObject retain];
	[state->strokeObject retain];
	[state->clipPath retain];
}

- (void)restore {
	if( stateIndex == 0 ) {	return; }
	
	EJCompositeOperation oldCompositeOp = state->globalCompositeOperation;
	EJPath *oldClipPath = state->clipPath;
	
	// Clean up current state
	[state->font release];
	[state->fillObject release];
	[state->strokeObject release];

	if( state->clipPath && state->clipPath != stateStack[stateIndex-1].clipPath ) {
		[self resetClip];
	}
	[state->clipPath release];
	
	// Load state from stack
	stateIndex--;
	state = &stateStack[stateIndex];
	
	path.transform = state->transform;
	
	// Set Composite op, if different
	if( state->globalCompositeOperation != oldCompositeOp ) {
		self.globalCompositeOperation = state->globalCompositeOperation;
	}
	
	// Render clip path, if present and different
	if( state->clipPath && state->clipPath != oldClipPath ) {
		[self setProgram:sharedGLContext.glProgram2DFlat];
		[state->clipPath drawPolygonsToContext:self fillRule:state->clipPath.fillRule target:kEJPathPolygonTargetDepth];
	}
}

- (void)rotate:(float)angle {
	state->transform = CGAffineTransformRotate( state->transform, angle );
	path.transform = state->transform;
}

- (void)translateX:(float)x y:(float)y {
	state->transform = CGAffineTransformTranslate( state->transform, x, y );
	path.transform = state->transform;
}

- (void)scaleX:(float)x y:(float)y {
	state->transform = CGAffineTransformScale( state->transform, x, y );
	path.transform = state->transform;
}

- (void)transformM11:(float)m11 m12:(float)m12 m21:(float)m21 m22:(float)m22 dx:(float)dx dy:(float)dy {
	CGAffineTransform t = CGAffineTransformMake( m11, m12, m21, m22, dx, dy );
	state->transform = CGAffineTransformConcat( t, state->transform );
	path.transform = state->transform;
}

- (void)setTransformM11:(float)m11 m12:(float)m12 m21:(float)m21 m22:(float)m22 dx:(float)dx dy:(float)dy {
	state->transform = CGAffineTransformMake( m11, m12, m21, m22, dx, dy );
	path.transform = state->transform;
}

- (void)drawImage:(EJTexture *)texture sx:(float)sx sy:(float)sy sw:(float)sw sh:(float)sh dx:(float)dx dy:(float)dy dw:(float)dw dh:(float)dh {
	
	float tw = texture.width;
	float th = texture.height;
	
	[self setProgram:sharedGLContext.glProgram2DTexture];
	[self setTexture:texture];
	[self pushTexturedRectX:dx y:dy w:dw h:dh tx:sx/tw ty:sy/th tw:sw/tw th:sh/th
		color:EJCanvasBlendWhiteColor(state) withTransform:state->transform];
}

- (void)fillRectX:(float)x y:(float)y w:(float)w h:(float)h {
	if( state->fillObject ) {
		[self pushFilledRectX:x y:y w:w h:h fillable:state->fillObject
			color:EJCanvasBlendWhiteColor(state) withTransform:state->transform];
	}
	else {
		[self setProgram:sharedGLContext.glProgram2DFlat];
		
		EJColorRGBA cc = EJCanvasBlendFillColor(state);
		[self pushRectX:x y:y w:w h:h
			color:cc withTransform:state->transform];
	}
}

- (void)strokeRectX:(float)x y:(float)y w:(float)w h:(float)h {
	// strokeRect should not affect the current path, so we create
	// a new, tempPath instead.
	EJPath *tempPath = [[EJPath alloc] init];
	tempPath.transform = state->transform;
	
	[tempPath moveToX:x y:y];
	[tempPath lineToX:x+w y:y];
	[tempPath lineToX:x+w y:y+h];
	[tempPath lineToX:x y:y+h];
	[tempPath close];
	
	[self setProgram:sharedGLContext.glProgram2DFlat];
	[tempPath drawLinesToContext:self];
	[tempPath release];
}

- (void)clearRectX:(float)x y:(float)y w:(float)w h:(float)h {
	[self setProgram:sharedGLContext.glProgram2DFlat];
	
	EJCompositeOperation oldOp = state->globalCompositeOperation;
	self.globalCompositeOperation = kEJCompositeOperationDestinationOut;
	
	static EJColorRGBA white = {.hex = 0xffffffff};
	[self pushRectX:x y:y w:w h:h color:white withTransform:state->transform];
	
	self.globalCompositeOperation = oldOp;
}

- (EJImageData*)getImageDataScaled:(float)scale flipped:(bool)flipped sx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh {
	
	[self flushBuffers];
	
	NSMutableData *pixels;
	
	// Fast case - no scaling, no flipping
	if( scale == 1 && !flipped ) {
		pixels = [NSMutableData dataWithLength:sw * sh * 4 * sizeof(GLubyte)];
		glReadPixels(sx, sy, sw, sh, GL_RGBA, GL_UNSIGNED_BYTE, pixels.mutableBytes);
	}
	
	// More processing needed - take care of the flipped screen layout and the scaling
	else {
		int internalWidth = sw * scale;
		int internalHeight = sh * scale;
		int internalX = sx * scale;
		int internalY = ((bufferHeight/scale)-sy-sh) * scale;
		
		EJColorRGBA *internalPixels = malloc( internalWidth * internalHeight * sizeof(EJColorRGBA));
		glReadPixels( internalX, internalY, internalWidth, internalHeight, GL_RGBA, GL_UNSIGNED_BYTE, internalPixels );
		
		int size = sw * sh * sizeof(EJColorRGBA);
		EJColorRGBA *scaledPixels = malloc( size );
		int index = 0;
		for( int y = 0; y < sh; y++ ) {
			int rowIndex = (int)((flipped ? sh-y-1 : y) * scale) * internalWidth;
			for( int x = 0; x < sw; x++ ) {
				int internalIndex = rowIndex + (int)(x * scale);
				scaledPixels[ index ] = internalPixels[ internalIndex ];
				index++;
			}
		}
		free(internalPixels);
	
		pixels = [NSMutableData dataWithBytesNoCopy:scaledPixels length:size];
	}
	
	return [[[EJImageData alloc] initWithWidth:sw height:sh pixels:pixels] autorelease];
}

- (EJImageData*)getImageDataSx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh {
	return [self getImageDataScaled:backingStoreRatio flipped:upsideDown sx:sx sy:sy sw:sw sh:sh];
}

- (EJImageData*)getImageDataHDSx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh {
	return [self getImageDataScaled:1 flipped:upsideDown sx:sx sy:sy sw:sw sh:sh];
}

- (void)putImageData:(EJImageData*)imageData scaled:(float)scale dx:(float)dx dy:(float)dy {
	EJTexture *texture = imageData.texture;
	[self setProgram:sharedGLContext.glProgram2DTexture];
	[self setTexture:texture];
	
	short tw = texture.width / scale;
	short th = texture.height / scale;
	
	static EJColorRGBA white = {.hex = 0xffffffff};
	
	EJCompositeOperation oldOp = state->globalCompositeOperation;
	self.globalCompositeOperation = kEJCompositeOperationCopy;
	
	[self pushTexturedRectX:dx y:dy w:tw h:th tx:0 ty:0 tw:1 th:1 color:white withTransform:CGAffineTransformIdentity];
	[self flushBuffers];
	
	self.globalCompositeOperation = oldOp;
}

- (void)putImageData:(EJImageData*)imageData dx:(float)dx dy:(float)dy {
	[self putImageData:imageData scaled:1 dx:dx dy:dy];
}

- (void)putImageDataHD:(EJImageData*)imageData dx:(float)dx dy:(float)dy {
	[self putImageData:imageData scaled:backingStoreRatio dx:dx dy:dy];
}

- (void)beginPath {
	[path reset];
}

- (void)closePath {
	[path close];
}

- (void)fill:(EJPathFillRule)fillRule {
	[self setProgram:sharedGLContext.glProgram2DFlat];
	[path drawPolygonsToContext:self fillRule:fillRule target:kEJPathPolygonTargetColor];
}

- (void)stroke {
	[self setProgram:sharedGLContext.glProgram2DFlat];
	[path drawLinesToContext:self];
}

- (void)moveToX:(float)x y:(float)y {
	[path moveToX:x y:y];
}

- (void)lineToX:(float)x y:(float)y {
	[path lineToX:x y:y];
}

- (void)bezierCurveToCpx1:(float)cpx1 cpy1:(float)cpy1 cpx2:(float)cpx2 cpy2:(float)cpy2 x:(float)x y:(float)y {
	float scale = CGAffineTransformGetScale( state->transform );
	[path bezierCurveToCpx1:cpx1 cpy1:cpy1 cpx2:cpx2 cpy2:cpy2 x:x y:y scale:scale];
}

- (void)quadraticCurveToCpx:(float)cpx cpy:(float)cpy x:(float)x y:(float)y {
	float scale = CGAffineTransformGetScale( state->transform );
	[path quadraticCurveToCpx:cpx cpy:cpy x:x y:y scale:scale];
}

- (void)rectX:(float)x y:(float)y w:(float)w h:(float)h {
	[path moveToX:x y:y];
	[path lineToX:x+w y:y];
	[path lineToX:x+w y:y+h];
	[path lineToX:x y:y+h];
	[path close];
}

- (void)arcToX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 radius:(float)radius {
	[path arcToX1:x1 y1:y1 x2:x2 y2:y2 radius:radius];
}

- (void)arcX:(float)x y:(float)y radius:(float)radius
	startAngle:(float)startAngle endAngle:(float)endAngle
	antiClockwise:(BOOL)antiClockwise
{
	[path arcX:x y:y radius:radius startAngle:startAngle endAngle:endAngle antiClockwise:antiClockwise];
}

- (void)fillText:(NSString *)text x:(float)x y:(float)y {
	float scale = CGAffineTransformGetScale( state->transform ) * backingStoreRatio;
	EJFont *font = [fontCache fontWithDescriptor:state->font contentScale:scale];
	
	[self setProgram:sharedGLContext.glProgram2DAlphaTexture];
	[font drawString:text toContext:self x:x y:y];
}

- (void)strokeText:(NSString *)text x:(float)x y:(float)y {
	float scale = CGAffineTransformGetScale( state->transform ) * backingStoreRatio;
	EJFont *font = [fontCache outlineFontWithDescriptor:state->font lineWidth:state->lineWidth contentScale:scale];
	
	[self setProgram:sharedGLContext.glProgram2DAlphaTexture];
	[font drawString:text toContext:self x:x y:y];
}

- (EJTextMetrics)measureText:(NSString *)text {
	float scale = CGAffineTransformGetScale( state->transform ) * backingStoreRatio;
	EJFont *font = [fontCache fontWithDescriptor:state->font contentScale:scale];
	return [font measureString:text forContext:self];
}

- (void)clip:(EJPathFillRule)fillRule {
	[self flushBuffers];
	[state->clipPath release];
	state->clipPath = nil;
	
	state->clipPath = path.copy;
	[self setProgram:sharedGLContext.glProgram2DFlat];
	[state->clipPath drawPolygonsToContext:self fillRule:fillRule target:kEJPathPolygonTargetDepth];
}

- (void)resetClip {
	if( state->clipPath ) {
		[self flushBuffers];
		[state->clipPath release];
		state->clipPath = nil;
		
		glDepthMask(GL_TRUE);
		glClear(GL_DEPTH_BUFFER_BIT);
		glDepthMask(GL_FALSE);
		glDepthFunc(GL_ALWAYS);
	}
}

@end
