#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#ifdef __cplusplus
extern "C" {
#endif

GLfloat *JSValueToGLfloatArray(JSContextRef ctx, JSValueRef value, GLsizei elementSize, GLsizei *numElements);
GLint *JSValueToGLintArray(JSContextRef ctx, JSValueRef value, GLsizei elementSize, GLsizei *numElements);
GLuint EJGetBytesPerPixel(GLenum type, GLenum format);

#define EJ_ARRAY_MATCHES_TYPE(ARRAY, TYPE) ( \
	(ARRAY == kJSTypedArrayTypeUint8Array && TYPE == GL_UNSIGNED_BYTE) || \
	(ARRAY == kJSTypedArrayTypeFloat32Array && TYPE == GL_FLOAT) || \
	(ARRAY == kJSTypedArrayTypeUint16Array && ( \
		TYPE == GL_UNSIGNED_SHORT_5_6_5 || \
		TYPE == GL_UNSIGNED_SHORT_4_4_4_4 || \
		TYPE == GL_UNSIGNED_SHORT_5_5_5_1 \
	)) \
)

#ifdef __cplusplus
}
#endif