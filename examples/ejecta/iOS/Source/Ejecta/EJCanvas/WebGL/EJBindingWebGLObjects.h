#import "EJBindingBase.h"
#import "EJBindingCanvasContextWebGL.h"
#import "EJTexture.h"

@interface EJBindingWebGLObject : EJBindingBase {
	GLuint index;
	EJBindingCanvasContextWebGL *webglContext;
}
- (id)initWithWebGLContext:(EJBindingCanvasContextWebGL *)webglContext index:(GLuint)index;
- (void)invalidate;
+ (GLuint)indexFromJSValue:(JSValueRef)value;
+ (EJBindingWebGLObject *)webGLObjectFromJSValue:(JSValueRef)value;
+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)scriptView
	webglContext:(EJBindingCanvasContextWebGL *)webglContext
	index:(GLuint)index;
@end


@interface EJBindingWebGLBuffer : EJBindingWebGLObject
@end


@interface EJBindingWebGLProgram : EJBindingWebGLObject
@end


@interface EJBindingWebGLShader : EJBindingWebGLObject
@end


@interface EJBindingWebGLTexture : EJBindingWebGLObject {
	EJTexture *texture;
}
+ (EJTexture *)textureFromJSValue:(JSValueRef)value;
+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)scriptView
	webglContext:(EJBindingCanvasContextWebGL *)webglContext;
@end


@interface EJBindingWebGLUniformLocation : EJBindingWebGLObject
@end


@interface EJBindingWebGLRenderbuffer : EJBindingWebGLObject
@end


@interface EJBindingWebGLFramebuffer : EJBindingWebGLObject
@end

@interface EJBindingWebGLVertexArrayObjectOES : EJBindingWebGLObject
@end

@interface EJBindingWebGLActiveInfo : EJBindingBase {
	GLint size;
	GLenum type;
	NSString *name;
}
- (id)initWithSize:(GLint)sizep type:(GLenum)typep name:(NSString *)namep;
+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)scriptView
	size:(GLint)sizep type:(GLenum)typep name:(NSString *)namep;
@end


@interface EJBindingWebGLShaderPrecisionFormat : EJBindingBase {
	GLint rangeMin;
	GLint rangeMax;
	GLint precision;
}
- (id)initWithRangeMin:(GLint)rangeMin rangeMax:(GLint)rangeMax precision:(GLint)precision;
+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)scriptView
	rangeMin:(GLint)rangeMin rangeMax:(GLint)rangeMax precision:(GLint)precision;
@end


@interface EJBindingWebGLContextAttributes : EJBindingBase
@end
