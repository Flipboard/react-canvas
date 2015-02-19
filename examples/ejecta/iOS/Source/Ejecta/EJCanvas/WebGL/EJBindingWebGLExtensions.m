#import "EJBindingWebGLExtensions.h"
#import "EJBindingCanvasContextWebGL.h"


const EJWebGLExtensionName EJWebGLExtensions[] = {
	{"EXT_texture_filter_anisotropic", "GL_EXT_texture_filter_anisotropic"},
	{"OES_texture_float", "GL_OES_texture_float"},
	{"OES_texture_half_float", "GL_OES_texture_half_float"},
	{"OES_texture_half_float_linear", "GL_OES_texture_half_float_linear"},
	{"OES_standard_derivatives", "GL_OES_standard_derivatives"},
	{"OES_vertex_array_object", "GL_OES_vertex_array_object"}
};

const int EJWebGLExtensionsCount = sizeof(EJWebGLExtensions) / sizeof(EJWebGLExtensionName);


@implementation EJBindingWebGLExtension

- (id)initWithWebGLContext:(EJBindingCanvasContextWebGL *)webglContextp {
	if( self = [super initWithContext:NULL argc:0 argv:NULL] ) {
		webglContext = [webglContextp retain];
	}
	return self;
}

- (void)dealloc {
	[webglContext release];
	[super dealloc];
}

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	webglContext:(EJBindingCanvasContextWebGL *)webglContext
{
	id native = [[self alloc] initWithWebGLContext:webglContext];
	
	JSObjectRef obj = [self createJSObjectWithContext:ctx scriptView:view instance:native];
	[native release];
	return obj;
}

@end


@implementation EJBindingWebGLExtensionEXT_texture_filter_anisotropic
EJ_BIND_CONST_GL(MAX_TEXTURE_MAX_ANISOTROPY_EXT);
EJ_BIND_CONST_GL(TEXTURE_MAX_ANISOTROPY_EXT);
@end


@implementation EJBindingWebGLExtensionOES_texture_float
@end


@implementation EJBindingWebGLExtensionOES_texture_half_float
EJ_BIND_CONST_GL(HALF_FLOAT_OES);
@end


@implementation EJBindingWebGLExtensionOES_texture_half_float_linear
@end


@implementation EJBindingWebGLExtensionOES_standard_derivatives
@end


@implementation EJBindingWebGLExtensionOES_vertex_array_object

EJ_BIND_FUNCTION(createVertexArrayOES, ctx, argc, argv) {
	GLuint vertexArray;
	scriptView.currentRenderingContext = webglContext.renderingContext;
	glGenVertexArraysOES(1, &vertexArray);
	JSObjectRef obj = [EJBindingWebGLVertexArrayObjectOES createJSObjectWithContext:ctx
		scriptView:scriptView webglContext:webglContext index:vertexArray];
	[webglContext addVertexArray:vertexArray obj:obj];
	return obj;
}

EJ_BIND_FUNCTION(deleteVertexArrayOES, ctx, argc, argv) { \
	if( argc < 1 ) { return NULL; }

	GLuint index = [EJBindingWebGLVertexArrayObjectOES indexFromJSValue:argv[0]];
	[webglContext deleteVertexArray:index];
	return NULL;
}

EJ_BIND_FUNCTION(isVertexArrayOES, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }

	scriptView.currentRenderingContext = webglContext.renderingContext;
	GLuint index = [EJBindingWebGLVertexArrayObjectOES indexFromJSValue:argv[0]];
	return JSValueMakeBoolean(ctx, glIsVertexArrayOES(index));
}

EJ_BIND_FUNCTION(bindVertexArrayOES, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }

	scriptView.currentRenderingContext = webglContext.renderingContext;
	GLuint index = [EJBindingWebGLVertexArrayObjectOES indexFromJSValue:argv[0]];
	glBindVertexArrayOES(index);
	return NULL;
}

// Constants
EJ_BIND_CONST_GL(VERTEX_ARRAY_BINDING_OES);

@end
