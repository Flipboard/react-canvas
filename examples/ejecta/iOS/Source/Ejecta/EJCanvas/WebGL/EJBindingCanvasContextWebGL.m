#import "EJBindingCanvasContextWebGL.h"
#import "EJBindingWebGLObjects.h"
#import "EJBindingWebGLExtensions.h"
#import "EJDrawable.h"
#import "EJTexture.h"
#import "EJConvertWebGL.h"
#import "EJJavaScriptView.h"

#import <JavaScriptCore/JSTypedArray.h>


@implementation EJBindingCanvasContextWebGL
@synthesize renderingContext;

- (id)initWithCanvas:(JSObjectRef)canvas renderingContext:(EJCanvasContextWebGL *)renderingContextp {
	if( self = [super initWithContext:NULL argc:0 argv:NULL] ) {
		renderingContext = [renderingContextp retain];
		jsCanvas = canvas;
		
		buffers = [NSMutableDictionary new];
		textures = [NSMutableDictionary new];
		programs = [NSMutableDictionary new];
		shaders = [NSMutableDictionary new];
		framebuffers = [NSMutableDictionary new];
		renderbuffers = [NSMutableDictionary new];

		vertexArrays = [NSMutableDictionary new];
		extensions = [NSMutableDictionary new];
		
		activeTexture = &textureUnits[0];
	}
	return self;
}

- (void)dealloc {
	// Make sure this rendering context is the current one, so all
	// OpenGL objects can be deleted properly.
	EAGLContext *oldContext = [EAGLContext currentContext];
	[EAGLContext setCurrentContext:renderingContext.glContext];
	
	for( NSNumber *n in buffers ) { GLuint buffer = n.intValue; glDeleteBuffers(1, &buffer); }
	[buffers release];
	
	for( NSNumber *n in programs ) { glDeleteProgram(n.intValue); }
	[programs release];
	
	for( NSNumber *n in shaders ) { glDeleteShader(n.intValue); }
	[shaders release];
	
	for( NSNumber *n in framebuffers ) { GLuint buffer = n.intValue; glDeleteFramebuffers(1, &buffer); }
	[framebuffers release];
	
	for( NSNumber *n in renderbuffers ) { GLuint buffer = n.intValue; glDeleteRenderbuffers(1, &buffer); }
	[renderbuffers release];
	
	[textures release];
	
	for( NSValue *v in extensions.allValues ) { JSValueUnprotectSafe(scriptView.jsGlobalContext, v.pointerValue); }
	[extensions release];
    
	for( NSNumber *n in vertexArrays ) { GLuint array = n.intValue; glDeleteVertexArraysOES(1, &array); }
	[vertexArrays release];
	
	// Unprotect all texture units
	for( int i = 0; i < EJ_CANVAS_MAX_TEXTURE_UNITS; i++ ) {
		JSValueUnprotectSafe(scriptView.jsGlobalContext, textureUnits[i].jsTexture);
		JSValueUnprotectSafe(scriptView.jsGlobalContext, textureUnits[i].jsCubeMap);
	}
    
	[EAGLContext setCurrentContext:oldContext];
	
	[renderingContext release];
	
	[super dealloc];
}

- (void)deleteBuffer:(GLuint)buffer {
	NSNumber *key = @(buffer);
	if( buffers[key] ) {
		scriptView.currentRenderingContext = renderingContext;
		glDeleteBuffers(1, &buffer);
		[buffers removeObjectForKey:key];
	}
}

- (void)deleteTexture:(GLuint)texture {
	// This just deletes the pointer to the JSObject; the texture itself
	// is retained and released by the binding
	[textures removeObjectForKey:@(texture)];
}

- (void)deleteProgram:(GLuint)program {
	NSNumber *key = @(program);
	if( programs[key] ) {
		scriptView.currentRenderingContext = renderingContext;
		glDeleteProgram(program);
		[programs removeObjectForKey:key];
	}
}

- (void)deleteShader:(GLuint)shader {
	NSNumber *key = @(shader);
	if( shaders[key] ) {
		scriptView.currentRenderingContext = renderingContext;
		glDeleteShader(shader);
		[shaders removeObjectForKey:key];
	}

}

- (void)deleteRenderbuffer:(GLuint)renderbuffer {
	NSNumber *key = @(renderbuffer);
	if( renderbuffers[key] ) {
		scriptView.currentRenderingContext = renderingContext;
		glDeleteRenderbuffers(1, &renderbuffer);
		[renderbuffers removeObjectForKey:key];
	}

}

- (void)deleteFramebuffer:(GLuint)framebuffer {
	NSNumber *key = @(framebuffer);
	if( framebuffers[key] ) {
		scriptView.currentRenderingContext = renderingContext;
		glDeleteFramebuffers(1, &framebuffer);
		[framebuffers removeObjectForKey:key];
	}

}

- (void)addVertexArray:(GLuint)vertexArray obj:(JSObjectRef)objp {
	vertexArrays[@(vertexArray)] = [NSValue valueWithPointer:objp];
}

- (void)deleteVertexArray:(GLuint)vertexArray {
	NSNumber *key = @(vertexArray);
	if( vertexArrays[key] ) {
		scriptView.currentRenderingContext = renderingContext;
		glDeleteVertexArraysOES(1, &vertexArray);
		[vertexArrays removeObjectForKey:key];
	}
}


EJ_BIND_GET(canvas, ctx) {
	return jsCanvas;
}

EJ_BIND_GET(drawingBufferWidth, ctx) {
	return JSValueMakeNumber(ctx, renderingContext.width * renderingContext.backingStoreRatio);
}

EJ_BIND_GET(drawingBufferHeight, ctx) {
	return JSValueMakeNumber(ctx, renderingContext.height * renderingContext.backingStoreRatio);
}



// ------------------------------------------------------------------------------------
// Methods

// Shorthand to directly bind a c function that only takes numbers
#define EJ_BIND_FUNCTION_DIRECT(NAME, BINDING, ...) \
	EJ_BIND_FUNCTION(NAME, ctx, argc, argv) { \
		if( argc < EJ_ARGC(__VA_ARGS__) ) { return NULL; } \
		scriptView.currentRenderingContext = renderingContext; \
		BINDING( EJ_MAP_EXT(0, _EJ_COMMA, _EJ_BIND_FUNCTION_DIRECT_UNPACK, __VA_ARGS__) ); \
		return NULL;\
	}
#define _EJ_BIND_FUNCTION_DIRECT_UNPACK(INDEX, IGNORED) JSValueToNumberFast(ctx, argv[INDEX])


EJ_BIND_FUNCTION(getContextAttributes, ctx, argc, argv) {
	return [EJBindingWebGLContextAttributes createJSObjectWithContext:ctx
		scriptView:scriptView
		instance:[[[EJBindingWebGLContextAttributes alloc] init] autorelease]];
}

EJ_BIND_FUNCTION(isContextLost, ctx, argc, argv) {
	return JSValueMakeBoolean(ctx, false);
}

EJ_BIND_FUNCTION(getSupportedExtensions, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	
	const char *allExtension = (const char *)glGetString(GL_EXTENSIONS);
	
	JSValueRef *args = malloc(EJWebGLExtensionsCount * sizeof(JSObjectRef));
	int count = 0;
	for( int i = 0; i < EJWebGLExtensionsCount; i++ ) {
		if( strstr(allExtension, EJWebGLExtensions[i].internalName) ) {
			args[count++] = NSStringToJSValue(ctx, @(EJWebGLExtensions[i].exposedName));
		}
	}
	JSObjectRef array = JSObjectMakeArray(ctx, count, args, NULL);
	
	free(args);
	return array;
}

EJ_BIND_FUNCTION(getExtension, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }

	scriptView.currentRenderingContext = renderingContext;
	
	NSString *name = JSValueToNSString(ctx, argv[0]);
	
	// If extension has been activated before just return the same extension object
	if( extensions[name] ) {
		return (JSObjectRef)[extensions[name] pointerValue];
	}
	
	// Find the internal name for the extension and check if it's available
	BOOL extensionAvialable = false;
	const char *exposedName = name.UTF8String;
	for( int i = 0; i < EJWebGLExtensionsCount; i++ ) {
		
		if( strcmp(exposedName, EJWebGLExtensions[i].exposedName) == 0 ) {
			const char *allExtension = (const char *)glGetString(GL_EXTENSIONS);
			extensionAvialable = (strstr(allExtension, EJWebGLExtensions[i].internalName) != NULL);
			break;
		}
	}
	
	if( !extensionAvialable ) {
		return NULL;
	}
	
	// Construct the extension binding and return it
	JSObjectRef jsExtension;
	NSString *fullClassName = [@"EJBindingWebGLExtension" stringByAppendingString:(NSString *)name];
	Class class = NSClassFromString(fullClassName);

	if( class && [class isSubclassOfClass:EJBindingWebGLExtension.class] ) {
		jsExtension = [class createJSObjectWithContext:ctx scriptView:scriptView webglContext:self];
		extensions[name] = [NSValue valueWithPointer:jsExtension];
		JSValueProtect(ctx, jsExtension);
		return jsExtension;
	}
	return NULL;
}

EJ_BIND_FUNCTION(activeTexture, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLenum texture = JSValueToNumberFast(ctx, argv[0]);
	GLuint index = texture - GL_TEXTURE0;
	if( index < EJ_CANVAS_MAX_TEXTURE_UNITS ) {
		activeTexture = &textureUnits[index];
		glActiveTexture(texture);
	}
	return NULL;
}

EJ_BIND_FUNCTION(attachShader, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLuint shader = [EJBindingWebGLShader indexFromJSValue:argv[1]];
	glAttachShader(program, shader);
	return NULL;
}

EJ_BIND_FUNCTION(bindAttribLocation, ctx, argc, argv) {
	if( argc < 3 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLuint index = JSValueToNumberFast(ctx, argv[1]);
	NSString *name = JSValueToNSString(ctx, argv[2]);
	
	glBindAttribLocation(program, index, [name UTF8String]);
	return NULL;
}


EJ_BIND_FUNCTION(bindBuffer, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	scriptView.currentRenderingContext = renderingContext;
	GLenum target = JSValueToNumberFast(ctx, argv[0]);
	GLuint index = [EJBindingWebGLBuffer indexFromJSValue:argv[1]];
	glBindBuffer(target, index);
	return NULL;
}

#define EJ_BIND_BIND(I, NAME) \
	EJ_BIND_FUNCTION(bind##NAME, ctx, argc, argv) { \
		if( argc < 2 ) { return NULL; } \
		scriptView.currentRenderingContext = renderingContext; \
		GLenum target = JSValueToNumberFast(ctx, argv[0]); \
		GLuint index = [EJBindingWebGL##NAME indexFromJSValue:argv[1]]; \
		if( index ) { \
			glBind##NAME(target, index); \
		} \
		else { \
			[renderingContext bind##NAME]; \
		} \
		renderingContext.bound##NAME = index; \
		return NULL; \
	}

	EJ_MAP(EJ_BIND_BIND, Renderbuffer, Framebuffer);

#undef EJ_BIND_BIND


EJ_BIND_FUNCTION(bindTexture, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLenum target = JSValueToNumberFast(ctx, argv[0]);
	EJTexture *texture = [EJBindingWebGLTexture textureFromJSValue:argv[1]];
	
	if( target == GL_TEXTURE_2D ) {
		JSValueUnprotectSafe(ctx, activeTexture->jsTexture);
		
		if( texture ) {
			[texture bindToTarget:target];
			JSValueProtect(ctx, argv[1]);
			
			activeTexture->jsTexture = (JSObjectRef)argv[1];
			activeTexture->texture = texture;
		}
		else {
			activeTexture->jsTexture = NULL;
			activeTexture->texture = NULL;
			glBindTexture(target, 0);
		}
	}
	else if( target == GL_TEXTURE_CUBE_MAP ) {
		JSValueUnprotectSafe(ctx, activeTexture->jsCubeMap);
		
		if( texture ) {
			[texture bindToTarget:target];
			JSValueProtect(ctx, argv[1]);
			
			activeTexture->jsCubeMap = (JSObjectRef)argv[1];
			activeTexture->cubeMap = texture;
		}
		else {
			activeTexture->jsCubeMap = NULL;
			activeTexture->cubeMap = NULL;
			glBindTexture(target, 0);
		}
	}
	
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(blendColor, glBlendColor, red, green, blue, alpha);
EJ_BIND_FUNCTION_DIRECT(blendEquation, glBlendEquation, mode);
EJ_BIND_FUNCTION_DIRECT(blendEquationSeparate, glBlendEquationSeparate, modeRGB, modeAlpha);
EJ_BIND_FUNCTION_DIRECT(blendFunc, glBlendFunc, sfactor, dfactor);
EJ_BIND_FUNCTION_DIRECT(blendFuncSeparate, glBlendFuncSeparate, srcRGB, dstRGB, srcAlpha, dstAlpha);

EJ_BIND_FUNCTION(bufferData, ctx, argc, argv) {
	if( argc < 3 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLenum target = JSValueToNumberFast(ctx, argv[0]);
	size_t size;
	GLvoid *buffer = JSTypedArrayGetDataPtr(ctx, argv[1], &size);
	GLenum usage = JSValueToNumberFast(ctx, argv[2]);

	if( buffer ) {
		glBufferData(target, size, buffer, usage);
	}
	else if( JSValueIsNumber(ctx, argv[1]) ){
		// 2nd param is not an array? Must be the size; initialize empty
		GLintptr psize = JSValueToNumberFast(ctx, argv[1]);
		glBufferData(target, psize, NULL, usage);
	}
	return NULL;
}

EJ_BIND_FUNCTION(bufferSubData, ctx, argc, argv) {
	if( argc < 3 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLenum target = JSValueToNumberFast(ctx, argv[0]);
	GLintptr offset = JSValueToNumberFast(ctx, argv[1]);
	
	size_t size;
	GLvoid *buffer = JSTypedArrayGetDataPtr(ctx, argv[2], &size);
	if( buffer ) {
		glBufferSubData(target, offset, size, buffer);
	}
	return NULL;
}

EJ_BIND_FUNCTION(checkFramebufferStatus, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target);
	
	scriptView.currentRenderingContext = renderingContext;
	
	return JSValueMakeNumber(ctx, glCheckFramebufferStatus(target));
}

EJ_BIND_FUNCTION(clear, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum mask);
	scriptView.currentRenderingContext = renderingContext;
	renderingContext.needsPresenting = YES;
	glClear(mask);
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(clearColor, glClearColor, red, green, blue, alpha);
EJ_BIND_FUNCTION_DIRECT(clearDepth, glClearDepthf, depth);
EJ_BIND_FUNCTION_DIRECT(clearStencil, glClearStencil, s);
EJ_BIND_FUNCTION_DIRECT(colorMask, glColorMask, red, green, blue, alpha);

EJ_BIND_FUNCTION(compileShader, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint shader = [EJBindingWebGLShader indexFromJSValue:argv[0]];
	glCompileShader(shader);
	return NULL;
}

EJ_BIND_FUNCTION_NOT_IMPLEMENTED(compressedTexImage2D);
EJ_BIND_FUNCTION_NOT_IMPLEMENTED(compressedTexSubImage2D);

EJ_BIND_FUNCTION(copyTexImage2D, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height);
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJTexture *targetTexture;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
	}
	else { // Assume CUBE_MAP
		targetTexture = activeTexture->cubeMap;
	}
	
	// We might need a new texture id, so rebind
	[targetTexture ensureMutableKeepPixels:NO forTarget:target];
	[targetTexture bindToTarget:target];
	
	glCopyTexImage2D(target, level, internalformat, x, y, width, height, 0);
	return NULL;
}

EJ_BIND_FUNCTION(copyTexSubImage2D, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJTexture *targetTexture;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
	}
	else { // Assume CUBE_MAP
		targetTexture = activeTexture->cubeMap;
	}
	
	// We might need a new texture id, so rebind
	[targetTexture ensureMutableKeepPixels:NO forTarget:target];
	[targetTexture bindToTarget:target];
	
	glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
	return NULL;
}

EJ_BIND_FUNCTION(createBuffer, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	GLuint index;
	glGenBuffers(1, &index);
	JSObjectRef obj = [EJBindingWebGLBuffer createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self index:index];
	buffers[@(index)] = [NSValue valueWithPointer:obj];
	return obj;
}

EJ_BIND_FUNCTION(createFramebuffer, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	GLuint index;
	glGenFramebuffers(1, &index);
	JSObjectRef obj = [EJBindingWebGLFramebuffer createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self index:index];
	framebuffers[@(index)] = [NSValue valueWithPointer:obj];
	return obj;
}

EJ_BIND_FUNCTION(createRenderbuffer, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	GLuint index;
	glGenRenderbuffers(1, &index);
	JSObjectRef obj = [EJBindingWebGLRenderbuffer createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self index:index];
	renderbuffers[@(index)] = [NSValue valueWithPointer:obj];
	return obj;
}

EJ_BIND_FUNCTION(createTexture, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	
	// The texture is initialized empty; it doesn't have a valid gl textureId, so we
	// can't put it in our textures dictionary just yet
	return [EJBindingWebGLTexture createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self];
}


EJ_BIND_FUNCTION(createProgram, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = glCreateProgram();
	JSObjectRef obj = [EJBindingWebGLProgram createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self index:program];
	programs[@(program)] = [NSValue valueWithPointer:obj];
	return obj;
}

EJ_BIND_FUNCTION(createShader, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum type);
	
	scriptView.currentRenderingContext = renderingContext;

	GLuint shader = glCreateShader(type);
	JSObjectRef obj = [EJBindingWebGLShader createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self index:shader];
	shaders[@(shader)] = [NSValue valueWithPointer:obj];
	return obj;
}

EJ_BIND_FUNCTION_DIRECT(cullFace, glCullFace, mode);


#define EJ_BIND_DELETE_OBJECT(I, NAME) \
	EJ_BIND_FUNCTION(delete##NAME, ctx, argc, argv) { \
		if( argc < 1 ) { return NULL; } \
		[[EJBindingWebGLObject webGLObjectFromJSValue:argv[0]] invalidate]; \
		return NULL; \
	}

	EJ_MAP(EJ_BIND_DELETE_OBJECT, Buffer, Framebuffer, Renderbuffer, Shader, Texture, Program);

#undef EJ_BIND_DELETE_OBJECT


EJ_BIND_FUNCTION_DIRECT(depthFunc, glDepthFunc, func);
EJ_BIND_FUNCTION_DIRECT(depthMask, glDepthMask, flag);
EJ_BIND_FUNCTION_DIRECT(depthRange, glDepthRangef, zNear, zFar);

EJ_BIND_FUNCTION(detachShader, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLuint shader = [EJBindingWebGLProgram indexFromJSValue:argv[1]];
	glDetachShader(program, shader);
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(disable, glDisable, cap);
EJ_BIND_FUNCTION_DIRECT(disableVertexAttribArray, glDisableVertexAttribArray, index);

EJ_BIND_FUNCTION(drawArrays, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum mode, GLint first, GLsizei count);
	
	scriptView.currentRenderingContext = renderingContext;
	renderingContext.needsPresenting = YES;
	
	glDrawArrays(mode, first, count);
	return NULL;
}

EJ_BIND_FUNCTION(drawElements, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum mode, GLsizei count, GLenum type, GLint offset);
	
	scriptView.currentRenderingContext = renderingContext;
	renderingContext.needsPresenting = YES;
	
	glDrawElements(mode, count, type, EJ_BUFFER_OFFSET(offset));
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(enable, glEnable, cap);
EJ_BIND_FUNCTION_DIRECT(enableVertexAttribArray, glEnableVertexAttribArray, index);

EJ_BIND_FUNCTION(flush, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	glFlush();
	return NULL;
}

EJ_BIND_FUNCTION(finish, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	glFinish();
	return NULL;
}

EJ_BIND_FUNCTION(framebufferRenderbuffer, ctx, argc, argv) {
	if( argc < 4 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJ_UNPACK_ARGV(GLenum target, GLenum attachment, GLenum renderbuffertarget);
	GLuint renderbuffer = [EJBindingWebGLRenderbuffer indexFromJSValue:argv[3]];
	
	if( attachment == GL_DEPTH_STENCIL_ATTACHMENT ) {
		glFramebufferRenderbuffer(target, GL_DEPTH_ATTACHMENT, renderbuffertarget, renderbuffer);
		glFramebufferRenderbuffer(target, GL_STENCIL_ATTACHMENT, renderbuffertarget, renderbuffer);
	}
	else {
		glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer);
	}
	return NULL;
}

EJ_BIND_FUNCTION(framebufferTexture2D, ctx, argc, argv) {
	if( argc < 5 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJ_UNPACK_ARGV(GLenum target, GLenum attachment, GLenum textarget);
	EJTexture *texture = [EJBindingWebGLTexture textureFromJSValue:argv[3]];
	EJ_UNPACK_ARGV_OFFSET(4, GLint level);
	
	[texture ensureMutableKeepPixels:NO forTarget:GL_TEXTURE_2D];
	[texture bindToTarget:GL_TEXTURE_2D];
	glFramebufferTexture2D(target, attachment, textarget, texture.textureId, level);
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(frontFace, glFrontFace, mode);
EJ_BIND_FUNCTION_DIRECT(generateMipmap, glGenerateMipmap, mode);

EJ_BIND_FUNCTION(getActiveAttrib, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLuint index = JSValueToNumberFast(ctx, argv[1]);
	
	GLint buffsize;
	glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &buffsize);
	
	GLchar *namebuffer = malloc(buffsize);
	GLsizei length;
	GLint size;
	GLenum type;
	glGetActiveAttrib(program, index, buffsize, &length, &size, &type, namebuffer);
	
	NSString *name = @(namebuffer);
	free(namebuffer);
	
	return [EJBindingWebGLActiveInfo createJSObjectWithContext:ctx
		scriptView:scriptView size:size type:type name:name];
}

EJ_BIND_FUNCTION(getActiveUniform, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLuint index = JSValueToNumberFast(ctx, argv[1]);
	
	GLint buffsize;
	glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &buffsize);
	
	GLchar *namebuffer = malloc(buffsize);
	GLsizei length;
	GLint size;
	GLenum type;
	glGetActiveUniform(program, index, buffsize, &length, &size, &type, namebuffer);
	
	NSString *name = @(namebuffer);
	free(namebuffer);
	
	return [EJBindingWebGLActiveInfo createJSObjectWithContext:ctx
		scriptView:scriptView size:size type:type name:name];
}

EJ_BIND_FUNCTION(getAttachedShaders, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	
	GLint count;
	glGetProgramiv(program, GL_ATTACHED_SHADERS, &count);
	
	GLuint *list = malloc(count * sizeof(GLuint));
	glGetAttachedShaders(program, count, NULL, list);
	
	JSValueRef *args = malloc(count * sizeof(JSObjectRef));
	for( int i = 0; i < count; i++ ) {
		args[i] = [shaders[@(list[i])] pointerValue];
	}
	JSObjectRef array = JSObjectMakeArray(ctx, count, args, NULL);
	free(args);
	free(list);
	
	return array;
}

EJ_BIND_FUNCTION(getAttribLocation, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	NSString *name = JSValueToNSString(ctx, argv[1]);

	return JSValueMakeNumber(ctx, glGetAttribLocation(program, [name UTF8String]));
}

EJ_BIND_FUNCTION(getParameter, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	JSValueRef ret = NULL;
	
	int intbuffer[4];
	float floatvalue;
	JSValueRef arrayArgs[4];
	
	switch( pname ) {
		// Float32Array (with 0 elements)
		case GL_COMPRESSED_TEXTURE_FORMATS:
			ret = JSTypedArrayMake(ctx, kJSTypedArrayTypeFloat32Array, 0);
			break;
			
		// Float32Array (with 2 elements) 
		case GL_ALIASED_LINE_WIDTH_RANGE:
		case GL_ALIASED_POINT_SIZE_RANGE:
		case GL_DEPTH_RANGE:
			ret = JSTypedArrayMake(ctx, kJSTypedArrayTypeFloat32Array, 2);
			glGetFloatv(pname, JSTypedArrayGetDataPtr(ctx, ret, NULL));
			break;
		
		// Float32Array (with 4 values)
		case GL_BLEND_COLOR:
		case GL_COLOR_CLEAR_VALUE:
			ret = JSTypedArrayMake(ctx, kJSTypedArrayTypeFloat32Array, 4);
			glGetFloatv(pname, JSTypedArrayGetDataPtr(ctx, ret, NULL));
			break;
			
		// Int32Array (with 2 values)
		case GL_MAX_VIEWPORT_DIMS:
			ret = JSTypedArrayMake(ctx, kJSTypedArrayTypeInt32Array, 2);
			glGetIntegerv(pname, JSTypedArrayGetDataPtr(ctx, ret, NULL));
			break;
			
		// Int32Array (with 4 values)
		case GL_SCISSOR_BOX:
		case GL_VIEWPORT:
			ret = JSTypedArrayMake(ctx, kJSTypedArrayTypeInt32Array, 4);
			glGetIntegerv(pname, JSTypedArrayGetDataPtr(ctx, ret, NULL));
			break;
		
		// boolean[] (with 4 values)
		case GL_COLOR_WRITEMASK:
			glGetIntegerv(pname, intbuffer);
			for(int i = 0; i < 4; i++ ) {
				arrayArgs[i] = JSValueMakeBoolean(ctx, intbuffer[i]);
			}
			ret = JSObjectMakeArray(ctx, 4, arrayArgs, NULL);
			break;

		// WebGLBuffer
		case GL_ARRAY_BUFFER_BINDING:
		case GL_ELEMENT_ARRAY_BUFFER_BINDING:
			glGetIntegerv(pname, intbuffer);
			ret = [buffers[@(intbuffer[0])] pointerValue];
			break;
		
		// WebGLProgram
		case GL_CURRENT_PROGRAM:
			glGetIntegerv(pname, intbuffer);
			ret = [programs[@(intbuffer[0])] pointerValue];
			break;
		
		// WebGLFramebuffer
		case GL_FRAMEBUFFER_BINDING:
			glGetIntegerv(pname, intbuffer);
			ret = [framebuffers[@(intbuffer[0])] pointerValue];
			break;
			
		// WebGLRenderbuffer
		case GL_RENDERBUFFER_BINDING:
			glGetIntegerv(pname, intbuffer);
			ret = [renderbuffers[@(intbuffer[0])] pointerValue];
			break;
		
		// WebGLTexture
		case GL_TEXTURE_BINDING_2D:
		case GL_TEXTURE_BINDING_CUBE_MAP:
			glGetIntegerv(pname, intbuffer);
			ret = [textures[@(intbuffer[0])] pointerValue];
			break;
			
		// Ejecta/WebGL specific
		case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
			// device may support more, but we only map 8 here
			ret = JSValueMakeNumber(ctx, EJ_CANVAS_MAX_TEXTURE_UNITS);
			break;
		
		case GL_UNPACK_FLIP_Y_WEBGL:
			ret = JSValueMakeBoolean(ctx, unpackFlipY);
			break;
			
		case GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
			ret = JSValueMakeBoolean(ctx, premultiplyAlpha);
			break;
		
		case GL_UNPACK_COLORSPACE_CONVERSION_WEBGL:
			ret = JSValueMakeBoolean(ctx, false);
			break;
			
		// string
		case GL_RENDERER:
		case GL_SHADING_LANGUAGE_VERSION:
		case GL_VENDOR:
		case GL_VERSION:
			ret = NSStringToJSValue(ctx, @((char *)glGetString(pname)));
			break;
		
		// single float
		case GL_DEPTH_CLEAR_VALUE:
		case GL_LINE_WIDTH:
		case GL_POLYGON_OFFSET_FACTOR:
		case GL_POLYGON_OFFSET_UNITS:
		case GL_SAMPLE_COVERAGE_VALUE:
			glGetFloatv(pname, &floatvalue);
			ret = JSValueMakeNumber(ctx, floatvalue);
			break;
		
		// single int/long/bool - everything else
		default:
			glGetIntegerv(pname, intbuffer);
			ret = JSValueMakeNumber(ctx, intbuffer[0]);
			break;
	}
	
	// That was fun!
	
	return ret;
}

EJ_BIND_FUNCTION(getBufferParameter, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLint param;
	glGetBufferParameteriv(target, pname, &param);
	return JSValueMakeNumber(ctx, param);
}

EJ_BIND_FUNCTION(getError, ctx, argc, argv) {
	scriptView.currentRenderingContext = renderingContext;
	return JSValueMakeNumber(ctx, glGetError());
}

EJ_BIND_FUNCTION(getFramebufferAttachmentParameter, ctx, argc, argv) {	
	EJ_UNPACK_ARGV(GLenum target, GLenum attachment, GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLint param;
	glGetFramebufferAttachmentParameteriv(target, attachment, pname, &param);
	
	if( pname == GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME ) {
		// Object names have to be wrapped in a WebGLObject, so figure out the type first
		GLint ptype;
		glGetFramebufferAttachmentParameteriv(target, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, &ptype);
		
		if( ptype == GL_RENDERBUFFER ) {
			return [renderbuffers[@(param)] pointerValue];
		}
		else if( ptype == GL_TEXTURE ) {
			return [textures[@(param)] pointerValue];
		}
	}
	
	return JSValueMakeNumber(ctx, param);
}

EJ_BIND_FUNCTION(getProgramParameter, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLenum pname = JSValueToNumberFast(ctx, argv[1]);
	
	GLint value;
	glGetProgramiv(program, pname, &value);
	return JSValueMakeNumber(ctx, value);
}

EJ_BIND_FUNCTION(getProgramInfoLog, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	
	// Get the info log size
	GLint size;
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &size);
	
	// Get the actual log message and return it
	GLchar *message = (GLchar *)malloc(size);
	glGetProgramInfoLog(program, size, &size, message);
	
	JSStringRef jss = JSStringCreateWithUTF8CString(message);
	JSValueRef ret = JSValueMakeString(ctx, jss);
	
	JSStringRelease(jss);
	free(message);
	
	return ret;
}

EJ_BIND_FUNCTION(getRenderbufferParameter, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLint value;
	glGetRenderbufferParameteriv(target, pname, &value);
	return JSValueMakeNumber(ctx, value);
}

EJ_BIND_FUNCTION(getShaderParameter, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint shader = [EJBindingWebGLShader indexFromJSValue:argv[0]];
	GLenum pname = JSValueToNumberFast(ctx, argv[1]);
	
	GLint value;
	glGetShaderiv(shader, pname, &value);
	
	if( pname == GL_DELETE_STATUS || pname == GL_COMPILE_STATUS ) {
		return JSValueMakeBoolean(ctx, value);
	}
	else { // GL_SHADER_TYPE || GL_INFO_LOG_LENGTH || GL_SHADER_SOURCE_LENGTH
		return JSValueMakeNumber(ctx, value);
	}
}

EJ_BIND_FUNCTION(getShaderPrecisionFormat, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum shadertype, GLenum precisiontype);
	
	if( shadertype != GL_VERTEX_SHADER && shadertype != GL_FRAGMENT_SHADER ) {
		return NULL;
	}
	
	GLint rangeMin, rangeMax, precision;
	switch( precisiontype ) {
		case GL_LOW_INT:
		case GL_MEDIUM_INT:
		case GL_HIGH_INT:
			// These values are for a 32-bit twos-complement integer format.
			rangeMin = 31;
			rangeMax = 30;
			precision = 0;
			break;
		case GL_LOW_FLOAT:
		case GL_MEDIUM_FLOAT:
		case GL_HIGH_FLOAT:
			// These values are for an IEEE single-precision floating-point format.
			rangeMin = 127;
			rangeMax = 127;
			precision = 23;
			break;
		default:
			return NULL;
	}
	
	return [EJBindingWebGLShaderPrecisionFormat	createJSObjectWithContext:ctx
		scriptView:scriptView rangeMin:rangeMin rangeMax:rangeMax precision:precision];
}

EJ_BIND_FUNCTION(getShaderInfoLog, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint shader = [EJBindingWebGLShader indexFromJSValue:argv[0]];

	// Get the info log size
	GLint size;
	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &size);
	
	// Get the actual log message and return it
	GLchar *message = (GLchar *)malloc(size);
	glGetShaderInfoLog(shader, size, &size, message);
	
	JSStringRef jss = JSStringCreateWithUTF8CString(message);
	JSValueRef ret = JSValueMakeString(ctx, jss);

	JSStringRelease(jss);
	free(message);
	
	return ret;
}

EJ_BIND_FUNCTION(getShaderSource, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint shader = [EJBindingWebGLShader indexFromJSValue:argv[0]];
	// Get the info log size
	GLint size;
	glGetShaderiv(shader, GL_SHADER_SOURCE_LENGTH, &size);
	
	// Get the actual shader source and return it
	GLchar *source = (GLchar *)malloc(size);
	glGetShaderSource(shader, size, &size, source);
	
	JSStringRef jss = JSStringCreateWithUTF8CString(source);
	JSValueRef ret = JSValueMakeString(ctx, jss);

	JSStringRelease(jss);
	free(source);
	
	return ret;
}

EJ_BIND_FUNCTION(getTexParameter, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLint value = 0;
	if( target == GL_TEXTURE_2D ) {
		value = [activeTexture->texture getParam:pname];
	}
	else if( target == GL_TEXTURE_CUBE_MAP ) {
		value = [activeTexture->cubeMap getParam:pname];
	}
	
	return JSValueMakeNumber(ctx, value);
}

EJ_BIND_FUNCTION(getUniform, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	GLuint uniform = [EJBindingWebGLUniformLocation indexFromJSValue:argv[1]];
	
	
	// Oh Uniform
	// how can I get thy type?
	
	// I can't get thy type
	// from a location
	// I can get thy type
	// from an index
	
	// I can't get thy index
	// from a location
	// I can get thy location
	// from a name
	
	// I can get thy name
	// from an index
	
	// I can iterate all indices
	
	GLint numUniforms;
	glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &numUniforms);
	
	GLint nameLength;
	glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &nameLength);
	
	BOOL found = false;
	GLint numElements;
	GLenum elementType;
	GLchar *nameBuffer = malloc(nameLength);
	
	for( int i = 0; i < numUniforms; i++ ) {
		glGetActiveUniform(program, i, nameLength, NULL, &numElements, &elementType, nameBuffer);
		if( glGetUniformLocation(program, nameBuffer) == uniform ) {
			found = true;
			break;
		}
	}
	
	free(nameBuffer);
	if( !found ) { return NULL; }
	
	
	
	// Figure out the element type and size
	GLint type = GL_NONE, size = 0;
	switch( elementType ) {
		case GL_FLOAT:		type = GL_FLOAT; size = 1; break;
		case GL_FLOAT_VEC2:	type = GL_FLOAT; size = 2; break;
		case GL_FLOAT_VEC3:	type = GL_FLOAT; size = 3; break;
		case GL_FLOAT_VEC4:	type = GL_FLOAT; size = 4; break;
		case GL_BOOL:		type = GL_BOOL;	 size = 1; break;
		case GL_BOOL_VEC2:	type = GL_BOOL;	 size = 2; break;
		case GL_BOOL_VEC3:	type = GL_BOOL;	 size = 3; break;
		case GL_BOOL_VEC4:	type = GL_BOOL;	 size = 4; break;
		case GL_INT:		type = GL_INT;	 size = 1; break;
		case GL_INT_VEC2:	type = GL_INT;	 size = 2; break;
		case GL_INT_VEC3:	type = GL_INT;	 size = 3; break;
		case GL_INT_VEC4:	type = GL_INT;	 size = 4; break;
		case GL_FLOAT_MAT2:	type = GL_FLOAT; size = 4; break;
		case GL_FLOAT_MAT3:	type = GL_FLOAT; size = 9; break;
		case GL_FLOAT_MAT4:	type = GL_FLOAT; size = 16; break;
	};
	
	// Single value
	if( size == 1 ) {
		if( type == GL_FLOAT ) {
			float value;
			glGetUniformfv(program, uniform, &value);
			return JSValueMakeNumber(ctx, value);
		}
		else if( type == GL_INT ) {
			int value;
			glGetUniformiv(program, uniform, &value);
			return JSValueMakeNumber(ctx, value);
		}
		else if( type == GL_BOOL ) {
			int value;
			glGetUniformiv(program, uniform, &value);
			return JSValueMakeBoolean(ctx, value);
		}
	}
	
	
	JSObjectRef array = NULL;
	
	// Float32Array
	if( type == GL_FLOAT ) {
		array = JSTypedArrayMake(ctx, kJSTypedArrayTypeFloat32Array, size);
		void *buffer = JSTypedArrayGetDataPtr(ctx, array, NULL);
		glGetUniformfv(program, uniform, buffer);
	}
	
	// Int32Array
	else if( type == GL_INT ) {
		array = JSTypedArrayMake(ctx, kJSTypedArrayTypeInt32Array, size);
		void *buffer = JSTypedArrayGetDataPtr(ctx, array, NULL);
		glGetUniformiv(program, uniform, buffer);
	}
	
	// boolean[]
	else if( type == GL_BOOL ) {
		int buffer[size];
		JSValueRef arrayArgs[size];
		
		glGetUniformiv(program, uniform, buffer);
		for( int i = 0; i < size; i++ ) {
			arrayArgs[i] = JSValueMakeBoolean(ctx, buffer[i]);
		}
		array = JSObjectMakeArray(ctx, size, arrayArgs, NULL);
	}
	
	return array;
}

EJ_BIND_FUNCTION(getUniformLocation, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	NSString *name = JSValueToNSString(ctx, argv[1]);
	
	GLint uniform = glGetUniformLocation(program, [name UTF8String]);
	if( uniform == -1 ) {
		return JSValueMakeNull(ctx);
	}
	
	return [EJBindingWebGLUniformLocation createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:self index:uniform];
}

EJ_BIND_FUNCTION(getVertexAttrib, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLuint index, GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	if( pname == GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING ) {
		GLint buffer;
		glGetVertexAttribiv(index, pname, &buffer);
		return [buffers[@(buffer)] pointerValue];
	}
	else if( pname == GL_CURRENT_VERTEX_ATTRIB ) {
		JSObjectRef array = JSTypedArrayMake(ctx, kJSTypedArrayTypeFloat32Array, 4);
		GLint *values = JSTypedArrayGetDataPtr(ctx, array, NULL);
		glGetVertexAttribiv(index, pname, values);
		return array;
	}
	else {
		GLint value;
		glGetVertexAttribiv(index, pname, &value);
		return JSValueMakeNumber(ctx, value);
	}
}

EJ_BIND_FUNCTION(getVertexAttribOffset, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLuint index, GLenum pname);
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLvoid *pointer;
	glGetVertexAttribPointerv(index, pname, &pointer);
	return JSValueMakeNumber(ctx, (int)pointer);
}

EJ_BIND_FUNCTION_DIRECT(hint, glHint, target, mode);


#define EJ_BIND_IS_OBJECT(I, NAME) \
	EJ_BIND_FUNCTION(is##NAME, ctx, argc, argv) { \
		if( argc < 1 ) { return NULL; } \
		scriptView.currentRenderingContext = renderingContext; \
		GLuint index = [EJBindingWebGL##NAME indexFromJSValue:argv[0]]; \
		return JSValueMakeBoolean(ctx, glIs##NAME(index)); \
	}

	EJ_MAP(EJ_BIND_IS_OBJECT, Buffer, Framebuffer, Program, Renderbuffer, Shader);

#undef EJ_BIND_IS_OBJECT


EJ_BIND_FUNCTION_DIRECT(isEnabled, glIsEnabled, cap);

EJ_BIND_FUNCTION(isTexture, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJTexture *texture = [EJBindingWebGLTexture textureFromJSValue:argv[0]];
	return JSValueMakeBoolean(ctx, glIsTexture(texture.textureId));
}

EJ_BIND_FUNCTION_DIRECT(lineWidth, glLineWidth, width);

EJ_BIND_FUNCTION(linkProgram, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	glLinkProgram(program);
	return NULL;
}

EJ_BIND_FUNCTION(pixelStorei, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum pname, GLint param);
	
	switch( pname ) {
		case GL_UNPACK_FLIP_Y_WEBGL:
			unpackFlipY = param;
			break;
			
		case GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
			premultiplyAlpha = param;
			break;
		
		case GL_UNPACK_COLORSPACE_CONVERSION_WEBGL:
			if( param ) {
				NSLog(@"Warning: UNPACK_COLORSPACE_CONVERSION_WEBGL is unsupported");
			}
			break;
			
		default:
			scriptView.currentRenderingContext = renderingContext;
			glPixelStorei(pname, param);
			break;
	}
	
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(polygonOffset, glPolygonOffset, factor, units);

EJ_BIND_FUNCTION(readPixels, ctx, argc, argv) {
	if( argc < 7 ) { return NULL; }
	EJ_UNPACK_ARGV(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type);
	
	JSTypedArrayType arrayType = JSTypedArrayGetType(ctx, argv[6]);
	if( !EJ_ARRAY_MATCHES_TYPE(arrayType, type) ) {
		return NULL;
	}
	
	scriptView.currentRenderingContext = renderingContext;
	
	size_t size;
	void *pixels = JSTypedArrayGetDataPtr(ctx, argv[6], &size);
	
	GLuint bytesPerPixel = EJGetBytesPerPixel(type, format);
	if( bytesPerPixel && size >= width * height * bytesPerPixel ) {
		glReadPixels(x, y, width, height, format, type, pixels);
	}
	
	return NULL;
}

EJ_BIND_FUNCTION(renderbufferStorage, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJTexture *targetTexture = NULL;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
	}
	else if( target == GL_TEXTURE_CUBE_MAP ) {
		targetTexture = activeTexture->cubeMap;
	}
	
	if( internalformat == GL_DEPTH_STENCIL_OES ) {
		internalformat = GL_DEPTH24_STENCIL8_OES;
	}
	
	[targetTexture ensureMutableKeepPixels:NO forTarget:target];
	[targetTexture bindToTarget:target];
	glRenderbufferStorage(target, internalformat, width, height);
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(sampleCoverage, glSampleCoverage, value, invert);
EJ_BIND_FUNCTION_DIRECT(scissor, glScissor, x, y, width, height);

EJ_BIND_FUNCTION(shaderSource, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint shader = [EJBindingWebGLShader indexFromJSValue:argv[0]];
	const GLchar *source = [JSValueToNSString(ctx, argv[1]) UTF8String];
	
	glShaderSource(shader, 1, &source, NULL);
	return NULL;
}

EJ_BIND_FUNCTION_DIRECT(stencilFunc, glStencilFunc, func, ref, mask);
EJ_BIND_FUNCTION_DIRECT(stencilFuncSeparate, glStencilFuncSeparate, face, func, ref, mask);
EJ_BIND_FUNCTION_DIRECT(stencilMask, glStencilMask, mask);
EJ_BIND_FUNCTION_DIRECT(stencilMaskSeparate, glStencilMaskSeparate, face, mask);
EJ_BIND_FUNCTION_DIRECT(stencilOp, glStencilOp, fail, zfail, zpass);
EJ_BIND_FUNCTION_DIRECT(stencilOpSeparate, glStencilOpSeparate, face, fail, zfail, zpass);

EJ_BIND_FUNCTION(texImage2D, ctx, argc, argv) {
	if( argc < 6 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	
	// texImage2D has two signatures:
	// texImage2D(target, level, internalformat, format, type, image);
	// texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
	
	EJ_UNPACK_ARGV(GLenum target, GLint level, GLenum internalformat);
	
	
	EJTexture *targetTexture = NULL;
	JSObjectRef jsTargetTexture;
	GLenum bindTarget;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
		jsTargetTexture = activeTexture->jsTexture;
		bindTarget = GL_TEXTURE_2D;
	}
	else if( target >= GL_TEXTURE_CUBE_MAP_POSITIVE_X && target <= GL_TEXTURE_CUBE_MAP_NEGATIVE_Z ) {
		targetTexture = activeTexture->cubeMap;
		jsTargetTexture = activeTexture->jsCubeMap;
		bindTarget = GL_TEXTURE_CUBE_MAP;
	}
	else {
		return NULL;
	}
	
	
	// If this texture already has a texture id remember it, so we can remove it later
	// if it gets a new one
	GLint oldTextureId = targetTexture.textureId;
	
	// With EJDrawable (Image, Canvas or ImageData)
	if( argc == 6) {
		EJ_UNPACK_ARGV_OFFSET(3, GLenum format, GLenum type);
		
		NSObject<EJDrawable> *drawable = (NSObject<EJDrawable> *)JSValueGetPrivate(argv[5]);
		if( !drawable || ![drawable conformsToProtocol:@protocol(EJDrawable)] ) {
			NSLog(@"ERROR: texImage2D image is not an Image, ImageData or Canvas element");
			return NULL;
		}
		
		EJTexture *sourceTexture = drawable.texture;
		
		// We don't care about internalFormat, format or type params here; the source image will
		// always be GL_RGBA and loaded as GL_UNSIGNED_BYTE
		// FIXME?
		if(	targetTexture && sourceTexture && internalformat && format && type ) {
				
			// The fast case - no flipping, premultiplied, mip level == 0, TEXTURE_2D target
			// and the source was loaded from a static image -> we can just use the source
			if(
				!unpackFlipY && premultiplyAlpha &&
				level == 0 && target == GL_TEXTURE_2D &&
				!sourceTexture.isDynamic
			) {
				[targetTexture createWithTexture:sourceTexture];
			}
			
			// Needs more processing; accessing .pixels attempts to reload the source image
			// or uses glReadPixels to get the pixel data from the attached FBO
			else {
				GLubyte *pixels = sourceTexture.pixels.mutableBytes;
				if( pixels ) {
					short width = sourceTexture.width;
					short height = sourceTexture.height;
					if( unpackFlipY ) {
						[EJTexture flipPixelsY:pixels bytesPerRow:(width * 4) rows:height];
					}
					if( !premultiplyAlpha ) {
						[EJTexture unPremultiplyPixels:pixels to:pixels byteLength:(width * height * 4) format:GL_RGBA];
					}
					
					// If we write mip level 0, there's no point in keeping pixels
					BOOL keepPixels = (level != 0);
					
					[targetTexture ensureMutableKeepPixels:keepPixels forTarget:bindTarget];
					[targetTexture bindToTarget:bindTarget];
					glTexImage2D(target, level, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
				}
			}
		}
		
		[sourceTexture maybeReleaseStorage];
	}
	
	// With ArrayBufferView
	else if( argc == 9 ) {
		EJ_UNPACK_ARGV_OFFSET(3, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type);
		
		
		JSTypedArrayType arrayType = JSTypedArrayGetType(ctx, argv[8]);
		if( border == 0 && EJ_ARRAY_MATCHES_TYPE(arrayType, type) ) {
			int bytesPerPixel = EJGetBytesPerPixel(type, format);
			
			size_t byteLength;
			void *pixels = JSTypedArrayGetDataPtr(ctx, argv[8], &byteLength);
			
			if( bytesPerPixel && byteLength >= width * height * bytesPerPixel ) {
				if( unpackFlipY ) {
					[EJTexture flipPixelsY:pixels bytesPerRow:(width * bytesPerPixel) rows:height];
				}
				if( premultiplyAlpha ) {
					[EJTexture premultiplyPixels:pixels to:pixels byteLength:(width * height * bytesPerPixel) format:format];
				}
				
				// If we write mip level 0, there's no point in keeping pixels
				BOOL keepPixels = (level != 0);
				
				[targetTexture ensureMutableKeepPixels:keepPixels forTarget:bindTarget];
				[targetTexture bindToTarget:bindTarget];
				glTexImage2D(target, level, format, width, height, 0, format, type, pixels);
 			}
		}
		else if( JSValueIsNull(ctx, argv[8]) ) {
			[targetTexture ensureMutableKeepPixels:NO forTarget:bindTarget];
			[targetTexture bindToTarget:bindTarget];
			void *nulled = calloc(width * height, EJGetBytesPerPixel(type, format));
			glTexImage2D(target, level, format, width, height, 0, format, type, nulled);
			free(nulled);
		}
	}

	
	// Remove old texture, if different
	if( oldTextureId && oldTextureId != targetTexture.textureId ) {
		[textures removeObjectForKey:@(oldTextureId)];
	}
	
	// Bind and remember new texture id
	if( targetTexture.textureId && targetTexture.textureId != oldTextureId ) {
		[targetTexture bindToTarget:bindTarget];
		
		textures[@(targetTexture.textureId)] = [NSValue valueWithPointer:jsTargetTexture];
	}

	return NULL;
}


EJ_BIND_FUNCTION(texSubImage2D, ctx, argc, argv) {
	if( argc < 7 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	
	// texSubImage2D has two signatures:
	// texSubImage2D(target, level, xoffset, yoffset, format, type, image);
	// texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
	
	EJ_UNPACK_ARGV(GLenum target, GLint level, GLint xoffset, GLint yoffset);
	
	
	EJTexture *targetTexture = NULL;
	JSObjectRef jsTargetTexture;
	GLenum bindTarget;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
		jsTargetTexture = activeTexture->jsTexture;
		bindTarget = GL_TEXTURE_2D;
	}
	else if( target >= GL_TEXTURE_CUBE_MAP_POSITIVE_X && target <= GL_TEXTURE_CUBE_MAP_NEGATIVE_Z ) {
		targetTexture = activeTexture->cubeMap;
		jsTargetTexture = activeTexture->jsCubeMap;
		bindTarget = GL_TEXTURE_CUBE_MAP;
	}
	else {
		return NULL;
	}
	
	
	// If this texture already has a texture id remember it, so we can remove it later
	// if it gets a new one
	GLint oldTextureId = targetTexture.textureId;
	
	// With EJDrawable (Image, Canvas or ImageData)
	if( argc == 7) {
		EJ_UNPACK_ARGV_OFFSET(4, GLenum format, GLenum type);
		
		NSObject<EJDrawable> *drawable = (NSObject<EJDrawable> *)JSValueGetPrivate(argv[6]);
		if( !drawable || ![drawable conformsToProtocol:@protocol(EJDrawable)] ) {
			NSLog(@"ERROR: texSubImage2D image is not an Image, ImageData or Canvas element");
			return NULL;
		}
		
		EJTexture *sourceTexture = drawable.texture;
		
		// We don't care about internalFormat, format or type params here; the source image will
		// always be GL_RGBA and loaded as GL_UNSIGNED_BYTE
		// FIXME?
		if(	targetTexture && sourceTexture && format && type ) {
			
			// Load image pixels, proccess as neccessary, make sure the current texture
			// is mutable and update
		
			GLubyte *pixels = sourceTexture.pixels.mutableBytes;
			if( pixels ) {
				short width = sourceTexture.width;
				short height = sourceTexture.height;
				if( unpackFlipY ) {
					[EJTexture flipPixelsY:pixels bytesPerRow:(width * 4) rows:height];
				}
				if( !premultiplyAlpha ) {
					[EJTexture unPremultiplyPixels:pixels to:pixels byteLength:(width * height * 4) format:GL_RGBA];
				}
				
				// Always keep previous pixels when ensuring mutability, as we're just updating
				// a portion of the texture
				[targetTexture ensureMutableKeepPixels:YES forTarget:bindTarget];
				[targetTexture bindToTarget:bindTarget];
				glTexSubImage2D(target, level, xoffset, yoffset, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
			}
		}
		
		[sourceTexture maybeReleaseStorage];
	}
	
	// With ArrayBufferView
	else if( argc == 9 ) {
		EJ_UNPACK_ARGV_OFFSET(4, GLsizei width, GLsizei height, GLenum format, GLenum type);
		
		
		JSTypedArrayType arrayType = JSTypedArrayGetType(ctx, argv[8]);
		if( EJ_ARRAY_MATCHES_TYPE(arrayType, type) ) {
			int bytesPerPixel = EJGetBytesPerPixel(type, format);
			
			size_t byteLength;
			void *pixels = JSTypedArrayGetDataPtr(ctx, argv[8], &byteLength);
			
			if( bytesPerPixel && byteLength >= width * height * bytesPerPixel ) {
				if( unpackFlipY ) {
					[EJTexture flipPixelsY:pixels bytesPerRow:(width * bytesPerPixel) rows:height];
				}
				if( premultiplyAlpha ) {
					[EJTexture premultiplyPixels:pixels to:pixels byteLength:width*height*bytesPerPixel format:format];
				}
				
				// Always keep previous pixels when ensuring mutability, as we're just updating
				// a portion of the texture
				[targetTexture ensureMutableKeepPixels:YES forTarget:bindTarget];
				[targetTexture bindToTarget:bindTarget];
				glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
 			}
		}
		else if( JSValueIsNull(ctx, argv[8]) ) {
			[targetTexture ensureMutableKeepPixels:YES forTarget:bindTarget];
			[targetTexture bindToTarget:bindTarget];
			void *nulled = calloc(width * height, EJGetBytesPerPixel(type, format));
			glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, nulled);
			free(nulled);
		}
	}

	
	// Remove old texture, if different
	if( oldTextureId && oldTextureId != targetTexture.textureId ) {
		[textures removeObjectForKey:@(oldTextureId)];
	}
	
	// Bind and remember new texture id
	if( targetTexture.textureId && targetTexture.textureId != oldTextureId ) {
		[targetTexture bindToTarget:bindTarget];
		
		textures[@(targetTexture.textureId)] = [NSValue valueWithPointer:jsTargetTexture];
	}
	
	return NULL;
}

EJ_BIND_FUNCTION(texParameterf, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLenum pname, GLfloat param);
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJTexture *targetTexture = NULL;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
	}
	else if( target == GL_TEXTURE_CUBE_MAP ) {
		targetTexture = activeTexture->cubeMap;
	}
	[targetTexture setParam:pname param:param];
	[targetTexture bindToTarget:target]; // binding the texture will update its params
	
	return NULL;
}

EJ_BIND_FUNCTION(texParameteri, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLenum target, GLenum pname, GLint param);
	
	scriptView.currentRenderingContext = renderingContext;
	
	EJTexture *targetTexture = NULL;
	if( target == GL_TEXTURE_2D ) {
		targetTexture = activeTexture->texture;
	}
	else if( target == GL_TEXTURE_CUBE_MAP ) {
		targetTexture = activeTexture->cubeMap;
	}
	[targetTexture setParam:pname param:param];
	[targetTexture bindToTarget:target]; // binding the texture will update its params
	
	return NULL;
}


#define EJ_BIND_UNIFORM(NAME, ... ) \
	EJ_BIND_FUNCTION(uniform##NAME, ctx, argc, argv) { \
		if( argc < EJ_ARGC(__VA_ARGS__)+1 ) { return NULL; } \
		scriptView.currentRenderingContext = renderingContext; \
		GLuint uniform = [EJBindingWebGLUniformLocation indexFromJSValue:argv[0]]; \
		glUniform##NAME( uniform, EJ_MAP_EXT(1, _EJ_COMMA, _EJ_BIND_FUNCTION_DIRECT_UNPACK, __VA_ARGS__) ); \
		return NULL; \
	}

	EJ_BIND_UNIFORM(1f, x);
	EJ_BIND_UNIFORM(2f, x, y);
	EJ_BIND_UNIFORM(3f, x, y, z);
	EJ_BIND_UNIFORM(4f, x, y, z, w);
	EJ_BIND_UNIFORM(1i, x);
	EJ_BIND_UNIFORM(2i, x, y);
	EJ_BIND_UNIFORM(3i, x, y, z);
	EJ_BIND_UNIFORM(4i, x, y, z, w);

#undef EJ_BIND_UNIFORM


#define EJ_BIND_UNIFORM_V(NAME, LENGTH, TYPE) \
	EJ_BIND_FUNCTION(uniform##NAME, ctx, argc, argv) { \
		if ( argc < 2 ) { return NULL; } \
		GLuint uniform = [EJBindingWebGLUniformLocation indexFromJSValue:argv[0]]; \
		GLsizei count; \
		TYPE *values = JSValueTo##TYPE##Array(ctx, argv[1], LENGTH, &count); \
		if( values ) { \
			scriptView.currentRenderingContext = renderingContext; \
			glUniform##NAME(uniform, count, values); \
		} \
		return NULL; \
	}

	EJ_BIND_UNIFORM_V(1fv, 1, GLfloat);
	EJ_BIND_UNIFORM_V(2fv, 2, GLfloat);
	EJ_BIND_UNIFORM_V(3fv, 3, GLfloat);
	EJ_BIND_UNIFORM_V(4fv, 4, GLfloat);
	EJ_BIND_UNIFORM_V(1iv, 1, GLint);
	EJ_BIND_UNIFORM_V(2iv, 2, GLint);
	EJ_BIND_UNIFORM_V(3iv, 3, GLint);
	EJ_BIND_UNIFORM_V(4iv, 4, GLint);

#undef EJ_BIND_UNIFORM_V


#define EJ_BIND_UNIFORM_MATRIX_V(NAME, LENGTH, TYPE) \
	EJ_BIND_FUNCTION(uniformMatrix##NAME, ctx, argc, argv) { \
		if ( argc < 3 ) { return NULL; } \
		GLuint uniform = [EJBindingWebGLUniformLocation indexFromJSValue:argv[0]]; \
		GLboolean transpose = JSValueToNumberFast(ctx, argv[1]); \
		GLsizei count; \
		TYPE *values = JSValueTo##TYPE##Array(ctx, argv[2], LENGTH, &count); \
		if( values ) { \
			scriptView.currentRenderingContext = renderingContext; \
			glUniformMatrix##NAME(uniform, count, transpose, values); \
		} \
		return NULL; \
	}

	EJ_BIND_UNIFORM_MATRIX_V(2fv, 4, GLfloat);
	EJ_BIND_UNIFORM_MATRIX_V(3fv, 9, GLfloat);
	EJ_BIND_UNIFORM_MATRIX_V(4fv, 16, GLfloat);

#undef EJ_BIND_UNIFORM_MATRIX_V


EJ_BIND_FUNCTION(useProgram, ctx, argc, argv) {
	if ( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	glUseProgram(program);
	return NULL;
}

EJ_BIND_FUNCTION(validateProgram, ctx, argc, argv) {
	if ( argc < 1 ) { return NULL; }
	
	scriptView.currentRenderingContext = renderingContext;
	
	GLuint program = [EJBindingWebGLProgram indexFromJSValue:argv[0]];
	glValidateProgram(program);
	return NULL;
}


EJ_BIND_FUNCTION_DIRECT(vertexAttrib1f, glVertexAttrib1f, index, x);
EJ_BIND_FUNCTION_DIRECT(vertexAttrib2f, glVertexAttrib2f, index, x, y);
EJ_BIND_FUNCTION_DIRECT(vertexAttrib3f, glVertexAttrib3f, index, x, y, z);
EJ_BIND_FUNCTION_DIRECT(vertexAttrib4f, glVertexAttrib4f, index, x, y, z, w);


#define EJ_BIND_VERTEXATTRIB_V(NAME, LENGTH, TYPE) \
	EJ_BIND_FUNCTION(vertexAttrib##NAME, ctx, argc, argv) { \
		if ( argc < 2 ) { return NULL; } \
		GLuint index = JSValueToNumberFast(ctx, argv[0]); \
		GLsizei count; \
		TYPE *values = JSValueTo##TYPE##Array(ctx, argv[1], LENGTH, &count); \
		if( values ) { \
			scriptView.currentRenderingContext = renderingContext; \
			glVertexAttrib##NAME(index, values); \
		} \
		return NULL; \
	} \

	EJ_BIND_VERTEXATTRIB_V(1fv, 1, GLfloat);
	EJ_BIND_VERTEXATTRIB_V(2fv, 2, GLfloat);
	EJ_BIND_VERTEXATTRIB_V(3fv, 3, GLfloat);
	EJ_BIND_VERTEXATTRIB_V(4fv, 4, GLfloat);

#undef EJ_BIND_VERTEXATTRIB_V


EJ_BIND_FUNCTION(vertexAttribPointer, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLuint index, GLuint itemSize, GLenum type, GLboolean normalized, GLsizei stride, GLint offset);
	
	scriptView.currentRenderingContext = renderingContext;
	
	glVertexAttribPointer(index, itemSize, type, normalized, stride, EJ_BUFFER_OFFSET(offset));
	return NULL;
}

EJ_BIND_FUNCTION(viewport, ctx, argc, argv) {
	EJ_UNPACK_ARGV(GLint x, GLint y, GLsizei w, GLsizei h);
	
	scriptView.currentRenderingContext = renderingContext;
	
	float scale = renderingContext.backingStoreRatio;
	glViewport(x * scale, y * scale, w * scale, h * scale);
	return NULL;
}

#undef EJ_BIND_FUNCTION_DIRECT





// ------------------------------------------------------------------------------------
// Constants


// ClearBufferMask
EJ_BIND_CONST_GL(DEPTH_BUFFER_BIT);
EJ_BIND_CONST_GL(STENCIL_BUFFER_BIT);
EJ_BIND_CONST_GL(COLOR_BUFFER_BIT);

// Boolean
EJ_BIND_CONST_GL(FALSE);
EJ_BIND_CONST_GL(TRUE);

// BeginMode
EJ_BIND_CONST_GL(POINTS);
EJ_BIND_CONST_GL(LINES);
EJ_BIND_CONST_GL(LINE_LOOP);
EJ_BIND_CONST_GL(LINE_STRIP);
EJ_BIND_CONST_GL(TRIANGLES);
EJ_BIND_CONST_GL(TRIANGLE_STRIP);
EJ_BIND_CONST_GL(TRIANGLE_FAN);

// AlphaFunction (not supported in ES20);
// GL_NEVER
// GL_LESS
// GL_EQUAL
// GL_LEQUAL
// GL_GREATER
// GL_NOTEQUAL
// GL_GEQUAL
// GL_ALWAYS

// BlendingFactorDest
EJ_BIND_CONST_GL(ZERO);
EJ_BIND_CONST_GL(ONE);
EJ_BIND_CONST_GL(SRC_COLOR);
EJ_BIND_CONST_GL(ONE_MINUS_SRC_COLOR);
EJ_BIND_CONST_GL(SRC_ALPHA);
EJ_BIND_CONST_GL(ONE_MINUS_SRC_ALPHA);
EJ_BIND_CONST_GL(DST_ALPHA);
EJ_BIND_CONST_GL(ONE_MINUS_DST_ALPHA);

// BlendingFactorSrc
// GL_ZERO
// GL_ONE
EJ_BIND_CONST_GL(DST_COLOR);
EJ_BIND_CONST_GL(ONE_MINUS_DST_COLOR);
EJ_BIND_CONST_GL(SRC_ALPHA_SATURATE);
// GL_SRC_ALPHA

// GL_ONE_MINUS_SRC_ALPHA
// GL_DST_ALPHA
// GL_ONE_MINUS_DST_ALPHA

// BlendEquationSeparate
EJ_BIND_CONST_GL(FUNC_ADD);
EJ_BIND_CONST_GL(BLEND_EQUATION);
EJ_BIND_CONST_GL(BLEND_EQUATION_RGB);
EJ_BIND_CONST_GL(BLEND_EQUATION_ALPHA);

// BlendSubtract
EJ_BIND_CONST_GL(FUNC_SUBTRACT);
EJ_BIND_CONST_GL(FUNC_REVERSE_SUBTRACT);

// Separate Blend Functions
EJ_BIND_CONST_GL(BLEND_DST_RGB);
EJ_BIND_CONST_GL(BLEND_SRC_RGB);
EJ_BIND_CONST_GL(BLEND_DST_ALPHA);
EJ_BIND_CONST_GL(BLEND_SRC_ALPHA);
EJ_BIND_CONST_GL(CONSTANT_COLOR);
EJ_BIND_CONST_GL(ONE_MINUS_CONSTANT_COLOR);
EJ_BIND_CONST_GL(CONSTANT_ALPHA);
EJ_BIND_CONST_GL(ONE_MINUS_CONSTANT_ALPHA);
EJ_BIND_CONST_GL(BLEND_COLOR);

// Buffer Objects
EJ_BIND_CONST_GL(ARRAY_BUFFER);
EJ_BIND_CONST_GL(ELEMENT_ARRAY_BUFFER);
EJ_BIND_CONST_GL(ARRAY_BUFFER_BINDING);
EJ_BIND_CONST_GL(ELEMENT_ARRAY_BUFFER_BINDING);

EJ_BIND_CONST_GL(STREAM_DRAW);
EJ_BIND_CONST_GL(STATIC_DRAW);
EJ_BIND_CONST_GL(DYNAMIC_DRAW);

EJ_BIND_CONST_GL(BUFFER_SIZE);
EJ_BIND_CONST_GL(BUFFER_USAGE);

EJ_BIND_CONST_GL(CURRENT_VERTEX_ATTRIB);

// CullFaceMode
EJ_BIND_CONST_GL(FRONT);
EJ_BIND_CONST_GL(BACK);
EJ_BIND_CONST_GL(FRONT_AND_BACK);

// EnableCap
EJ_BIND_CONST_GL(TEXTURE_2D);
EJ_BIND_CONST_GL(CULL_FACE);
EJ_BIND_CONST_GL(BLEND);
EJ_BIND_CONST_GL(DITHER);
EJ_BIND_CONST_GL(STENCIL_TEST);
EJ_BIND_CONST_GL(DEPTH_TEST);
EJ_BIND_CONST_GL(SCISSOR_TEST);
EJ_BIND_CONST_GL(POLYGON_OFFSET_FILL);
EJ_BIND_CONST_GL(SAMPLE_ALPHA_TO_COVERAGE);
EJ_BIND_CONST_GL(SAMPLE_COVERAGE);

// ErrorCode
EJ_BIND_CONST_GL(NO_ERROR);
EJ_BIND_CONST_GL(INVALID_ENUM);
EJ_BIND_CONST_GL(INVALID_VALUE);
EJ_BIND_CONST_GL(INVALID_OPERATION);
EJ_BIND_CONST_GL(OUT_OF_MEMORY);

// FrontFaceDirection
EJ_BIND_CONST_GL(CW);
EJ_BIND_CONST_GL(CCW);

// GetPName
EJ_BIND_CONST_GL(LINE_WIDTH);
EJ_BIND_CONST_GL(ALIASED_POINT_SIZE_RANGE);
EJ_BIND_CONST_GL(ALIASED_LINE_WIDTH_RANGE);
EJ_BIND_CONST_GL(CULL_FACE_MODE);
EJ_BIND_CONST_GL(FRONT_FACE);
EJ_BIND_CONST_GL(DEPTH_RANGE);
EJ_BIND_CONST_GL(DEPTH_WRITEMASK);
EJ_BIND_CONST_GL(DEPTH_CLEAR_VALUE);
EJ_BIND_CONST_GL(DEPTH_FUNC);
EJ_BIND_CONST_GL(STENCIL_CLEAR_VALUE);
EJ_BIND_CONST_GL(STENCIL_FUNC);
EJ_BIND_CONST_GL(STENCIL_FAIL);
EJ_BIND_CONST_GL(STENCIL_PASS_DEPTH_FAIL);
EJ_BIND_CONST_GL(STENCIL_PASS_DEPTH_PASS);
EJ_BIND_CONST_GL(STENCIL_REF);
EJ_BIND_CONST_GL(STENCIL_VALUE_MASK);
EJ_BIND_CONST_GL(STENCIL_WRITEMASK);
EJ_BIND_CONST_GL(STENCIL_BACK_FUNC);
EJ_BIND_CONST_GL(STENCIL_BACK_FAIL);
EJ_BIND_CONST_GL(STENCIL_BACK_PASS_DEPTH_FAIL);
EJ_BIND_CONST_GL(STENCIL_BACK_PASS_DEPTH_PASS);
EJ_BIND_CONST_GL(STENCIL_BACK_REF);
EJ_BIND_CONST_GL(STENCIL_BACK_VALUE_MASK);
EJ_BIND_CONST_GL(STENCIL_BACK_WRITEMASK);
EJ_BIND_CONST_GL(VIEWPORT);
EJ_BIND_CONST_GL(SCISSOR_BOX);
// GL_SCISSOR_TEST
EJ_BIND_CONST_GL(COLOR_CLEAR_VALUE);
EJ_BIND_CONST_GL(COLOR_WRITEMASK);
EJ_BIND_CONST_GL(UNPACK_ALIGNMENT);
EJ_BIND_CONST_GL(PACK_ALIGNMENT);
EJ_BIND_CONST_GL(MAX_TEXTURE_SIZE);
EJ_BIND_CONST_GL(MAX_VIEWPORT_DIMS);
EJ_BIND_CONST_GL(SUBPIXEL_BITS);
EJ_BIND_CONST_GL(RED_BITS);
EJ_BIND_CONST_GL(GREEN_BITS);
EJ_BIND_CONST_GL(BLUE_BITS);
EJ_BIND_CONST_GL(ALPHA_BITS);
EJ_BIND_CONST_GL(DEPTH_BITS);
EJ_BIND_CONST_GL(STENCIL_BITS);
EJ_BIND_CONST_GL(POLYGON_OFFSET_UNITS);
// GL_POLYGON_OFFSET_FILL
EJ_BIND_CONST_GL(POLYGON_OFFSET_FACTOR);
EJ_BIND_CONST_GL(TEXTURE_BINDING_2D);
EJ_BIND_CONST_GL(SAMPLE_BUFFERS);
EJ_BIND_CONST_GL(SAMPLES);
EJ_BIND_CONST_GL(SAMPLE_COVERAGE_VALUE);
EJ_BIND_CONST_GL(SAMPLE_COVERAGE_INVERT);

// GetTextureParameter
// GL_TEXTURE_MAG_FILTER
// GL_TEXTURE_MIN_FILTER
// GL_TEXTURE_WRAP_S
// GL_TEXTURE_WRAP_T

EJ_BIND_CONST_GL(NUM_COMPRESSED_TEXTURE_FORMATS);
EJ_BIND_CONST_GL(COMPRESSED_TEXTURE_FORMATS);

// HintMode
EJ_BIND_CONST_GL(DONT_CARE);
EJ_BIND_CONST_GL(FASTEST);
EJ_BIND_CONST_GL(NICEST);

// HintTarget
EJ_BIND_CONST_GL(GENERATE_MIPMAP_HINT);

// DataType
EJ_BIND_CONST_GL(BYTE);
EJ_BIND_CONST_GL(UNSIGNED_BYTE);
EJ_BIND_CONST_GL(SHORT);
EJ_BIND_CONST_GL(UNSIGNED_SHORT);
EJ_BIND_CONST_GL(INT);
EJ_BIND_CONST_GL(UNSIGNED_INT);
EJ_BIND_CONST_GL(FLOAT);
EJ_BIND_CONST_GL(FIXED);

// PixelFormat
EJ_BIND_CONST_GL(DEPTH_COMPONENT);
EJ_BIND_CONST_GL(ALPHA);
EJ_BIND_CONST_GL(RGB);
EJ_BIND_CONST_GL(RGBA);
EJ_BIND_CONST_GL(LUMINANCE);
EJ_BIND_CONST_GL(LUMINANCE_ALPHA);

// PixelType
// GL_UNSIGNED_BYTE
EJ_BIND_CONST_GL(UNSIGNED_SHORT_4_4_4_4);
EJ_BIND_CONST_GL(UNSIGNED_SHORT_5_5_5_1);
EJ_BIND_CONST_GL(UNSIGNED_SHORT_5_6_5);

// Shaders
EJ_BIND_CONST_GL(FRAGMENT_SHADER);
EJ_BIND_CONST_GL(VERTEX_SHADER);
EJ_BIND_CONST_GL(MAX_VERTEX_ATTRIBS);
EJ_BIND_CONST_GL(MAX_VERTEX_UNIFORM_VECTORS);
EJ_BIND_CONST_GL(MAX_VARYING_VECTORS);
EJ_BIND_CONST_GL(MAX_COMBINED_TEXTURE_IMAGE_UNITS);
EJ_BIND_CONST_GL(MAX_VERTEX_TEXTURE_IMAGE_UNITS);
EJ_BIND_CONST_GL(MAX_TEXTURE_IMAGE_UNITS);
EJ_BIND_CONST_GL(MAX_FRAGMENT_UNIFORM_VECTORS);
EJ_BIND_CONST_GL(SHADER_TYPE);
EJ_BIND_CONST_GL(DELETE_STATUS);
EJ_BIND_CONST_GL(LINK_STATUS);
EJ_BIND_CONST_GL(VALIDATE_STATUS);
EJ_BIND_CONST_GL(ATTACHED_SHADERS);
EJ_BIND_CONST_GL(ACTIVE_UNIFORMS);
EJ_BIND_CONST_GL(ACTIVE_UNIFORM_MAX_LENGTH);
EJ_BIND_CONST_GL(ACTIVE_ATTRIBUTES);
EJ_BIND_CONST_GL(ACTIVE_ATTRIBUTE_MAX_LENGTH);
EJ_BIND_CONST_GL(SHADING_LANGUAGE_VERSION);
EJ_BIND_CONST_GL(CURRENT_PROGRAM);

// StencilFunction
EJ_BIND_CONST_GL(NEVER);
EJ_BIND_CONST_GL(LESS);
EJ_BIND_CONST_GL(EQUAL);
EJ_BIND_CONST_GL(LEQUAL);
EJ_BIND_CONST_GL(GREATER);
EJ_BIND_CONST_GL(NOTEQUAL);
EJ_BIND_CONST_GL(GEQUAL);
EJ_BIND_CONST_GL(ALWAYS);

// StencilOp
// GL_ZERO
EJ_BIND_CONST_GL(KEEP);
EJ_BIND_CONST_GL(REPLACE);
EJ_BIND_CONST_GL(INCR);
EJ_BIND_CONST_GL(DECR);
EJ_BIND_CONST_GL(INVERT);
EJ_BIND_CONST_GL(INCR_WRAP);
EJ_BIND_CONST_GL(DECR_WRAP);

// StringName
EJ_BIND_CONST_GL(VENDOR);
EJ_BIND_CONST_GL(RENDERER);
EJ_BIND_CONST_GL(VERSION);
EJ_BIND_CONST_GL(EXTENSIONS);

// TextureMagFilter
EJ_BIND_CONST_GL(NEAREST);
EJ_BIND_CONST_GL(LINEAR);

// TextureMinFilter
// GL_NEAREST
// GL_LINEAR
EJ_BIND_CONST_GL(NEAREST_MIPMAP_NEAREST);
EJ_BIND_CONST_GL(LINEAR_MIPMAP_NEAREST);
EJ_BIND_CONST_GL(NEAREST_MIPMAP_LINEAR);
EJ_BIND_CONST_GL(LINEAR_MIPMAP_LINEAR);

// TextureParameterName
EJ_BIND_CONST_GL(TEXTURE_MAG_FILTER);
EJ_BIND_CONST_GL(TEXTURE_MIN_FILTER);
EJ_BIND_CONST_GL(TEXTURE_WRAP_S);
EJ_BIND_CONST_GL(TEXTURE_WRAP_T);

// TextureTarget
// GL_TEXTURE_2D
EJ_BIND_CONST_GL(TEXTURE);

EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP);
EJ_BIND_CONST_GL(TEXTURE_BINDING_CUBE_MAP);
EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP_POSITIVE_X);
EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP_NEGATIVE_X);
EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP_POSITIVE_Y);
EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP_NEGATIVE_Y);
EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP_POSITIVE_Z);
EJ_BIND_CONST_GL(TEXTURE_CUBE_MAP_NEGATIVE_Z);
EJ_BIND_CONST_GL(MAX_CUBE_MAP_TEXTURE_SIZE);

// TextureUnit
EJ_BIND_CONST_GL(TEXTURE0);
EJ_BIND_CONST_GL(TEXTURE1);
EJ_BIND_CONST_GL(TEXTURE2);
EJ_BIND_CONST_GL(TEXTURE3);
EJ_BIND_CONST_GL(TEXTURE4);
EJ_BIND_CONST_GL(TEXTURE5);
EJ_BIND_CONST_GL(TEXTURE6);
EJ_BIND_CONST_GL(TEXTURE7);
EJ_BIND_CONST_GL(TEXTURE8);
EJ_BIND_CONST_GL(TEXTURE9);
EJ_BIND_CONST_GL(TEXTURE10);
EJ_BIND_CONST_GL(TEXTURE11);
EJ_BIND_CONST_GL(TEXTURE12);
EJ_BIND_CONST_GL(TEXTURE13);
EJ_BIND_CONST_GL(TEXTURE14);
EJ_BIND_CONST_GL(TEXTURE15);
EJ_BIND_CONST_GL(TEXTURE16);
EJ_BIND_CONST_GL(TEXTURE17);
EJ_BIND_CONST_GL(TEXTURE18);
EJ_BIND_CONST_GL(TEXTURE19);
EJ_BIND_CONST_GL(TEXTURE20);
EJ_BIND_CONST_GL(TEXTURE21);
EJ_BIND_CONST_GL(TEXTURE22);
EJ_BIND_CONST_GL(TEXTURE23);
EJ_BIND_CONST_GL(TEXTURE24);
EJ_BIND_CONST_GL(TEXTURE25);
EJ_BIND_CONST_GL(TEXTURE26);
EJ_BIND_CONST_GL(TEXTURE27);
EJ_BIND_CONST_GL(TEXTURE28);
EJ_BIND_CONST_GL(TEXTURE29);
EJ_BIND_CONST_GL(TEXTURE30);
EJ_BIND_CONST_GL(TEXTURE31);
EJ_BIND_CONST_GL(ACTIVE_TEXTURE);

// TextureWrapMode
EJ_BIND_CONST_GL(REPEAT);
EJ_BIND_CONST_GL(CLAMP_TO_EDGE);
EJ_BIND_CONST_GL(MIRRORED_REPEAT);

// Uniform Types
EJ_BIND_CONST_GL(FLOAT_VEC2);
EJ_BIND_CONST_GL(FLOAT_VEC3);
EJ_BIND_CONST_GL(FLOAT_VEC4);
EJ_BIND_CONST_GL(INT_VEC2);
EJ_BIND_CONST_GL(INT_VEC3);
EJ_BIND_CONST_GL(INT_VEC4);
EJ_BIND_CONST_GL(BOOL);
EJ_BIND_CONST_GL(BOOL_VEC2);
EJ_BIND_CONST_GL(BOOL_VEC3);
EJ_BIND_CONST_GL(BOOL_VEC4);
EJ_BIND_CONST_GL(FLOAT_MAT2);
EJ_BIND_CONST_GL(FLOAT_MAT3);
EJ_BIND_CONST_GL(FLOAT_MAT4);
EJ_BIND_CONST_GL(SAMPLER_2D);
EJ_BIND_CONST_GL(SAMPLER_CUBE);

// Vertex Arrays
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_ENABLED);
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_SIZE);
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_STRIDE);
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_TYPE);
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_NORMALIZED);
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_POINTER);
EJ_BIND_CONST_GL(VERTEX_ATTRIB_ARRAY_BUFFER_BINDING);

// Read Format
EJ_BIND_CONST_GL(IMPLEMENTATION_COLOR_READ_TYPE);
EJ_BIND_CONST_GL(IMPLEMENTATION_COLOR_READ_FORMAT);

// Shader Source
EJ_BIND_CONST_GL(COMPILE_STATUS);
EJ_BIND_CONST_GL(INFO_LOG_LENGTH);
EJ_BIND_CONST_GL(SHADER_SOURCE_LENGTH);
EJ_BIND_CONST_GL(SHADER_COMPILER);

// Shader Binary
EJ_BIND_CONST_GL(SHADER_BINARY_FORMATS);
EJ_BIND_CONST_GL(NUM_SHADER_BINARY_FORMATS);

// Shader Precision-Specified Types
EJ_BIND_CONST_GL(LOW_FLOAT);
EJ_BIND_CONST_GL(MEDIUM_FLOAT);
EJ_BIND_CONST_GL(HIGH_FLOAT);
EJ_BIND_CONST_GL(LOW_INT);
EJ_BIND_CONST_GL(MEDIUM_INT);
EJ_BIND_CONST_GL(HIGH_INT);

// Framebuffer Object.
EJ_BIND_CONST_GL(FRAMEBUFFER);
EJ_BIND_CONST_GL(RENDERBUFFER);

EJ_BIND_CONST_GL(RGBA4);
EJ_BIND_CONST_GL(RGB5_A1);
EJ_BIND_CONST_GL(RGB565);
EJ_BIND_CONST_GL(DEPTH_COMPONENT16);

// Not sure if it makes sense to alias STENCIL_INDEX or if it should be
// removed completely.
EJ_BIND_CONST(STENCIL_INDEX, GL_DEPTH_STENCIL_OES);
EJ_BIND_CONST(STENCIL_INDEX8, GL_DEPTH_STENCIL_OES);

EJ_BIND_CONST(DEPTH_STENCIL, GL_DEPTH_STENCIL_OES);

EJ_BIND_CONST_GL(RENDERBUFFER_WIDTH);
EJ_BIND_CONST_GL(RENDERBUFFER_HEIGHT);
EJ_BIND_CONST_GL(RENDERBUFFER_INTERNAL_FORMAT);
EJ_BIND_CONST_GL(RENDERBUFFER_RED_SIZE);
EJ_BIND_CONST_GL(RENDERBUFFER_GREEN_SIZE);
EJ_BIND_CONST_GL(RENDERBUFFER_BLUE_SIZE);
EJ_BIND_CONST_GL(RENDERBUFFER_ALPHA_SIZE);
EJ_BIND_CONST_GL(RENDERBUFFER_DEPTH_SIZE);
EJ_BIND_CONST_GL(RENDERBUFFER_STENCIL_SIZE);

EJ_BIND_CONST_GL(FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE);
EJ_BIND_CONST_GL(FRAMEBUFFER_ATTACHMENT_OBJECT_NAME);
EJ_BIND_CONST_GL(FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL);
EJ_BIND_CONST_GL(FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE);

EJ_BIND_CONST_GL(COLOR_ATTACHMENT0);
EJ_BIND_CONST_GL(DEPTH_ATTACHMENT);
EJ_BIND_CONST_GL(STENCIL_ATTACHMENT);
EJ_BIND_CONST_GL(DEPTH_STENCIL_ATTACHMENT);


EJ_BIND_CONST_GL(NONE);

EJ_BIND_CONST_GL(FRAMEBUFFER_COMPLETE);
EJ_BIND_CONST_GL(FRAMEBUFFER_INCOMPLETE_ATTACHMENT);
EJ_BIND_CONST_GL(FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT);
EJ_BIND_CONST_GL(FRAMEBUFFER_INCOMPLETE_DIMENSIONS);
EJ_BIND_CONST_GL(FRAMEBUFFER_UNSUPPORTED);

EJ_BIND_CONST_GL(FRAMEBUFFER_BINDING);
EJ_BIND_CONST_GL(RENDERBUFFER_BINDING);
EJ_BIND_CONST_GL(MAX_RENDERBUFFER_SIZE);

EJ_BIND_CONST_GL(INVALID_FRAMEBUFFER_OPERATION);

// WebGL-specific enums
EJ_BIND_CONST_GL(UNPACK_FLIP_Y_WEBGL);
EJ_BIND_CONST_GL(UNPACK_PREMULTIPLY_ALPHA_WEBGL);
EJ_BIND_CONST_GL(CONTEXT_LOST_WEBGL);
EJ_BIND_CONST_GL(UNPACK_COLORSPACE_CONVERSION_WEBGL);
EJ_BIND_CONST_GL(BROWSER_DEFAULT_WEBGL);

#undef EJ_BIND_CONST_GL

@end
