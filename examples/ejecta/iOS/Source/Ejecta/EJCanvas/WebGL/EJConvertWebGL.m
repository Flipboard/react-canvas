#import "EJConvertWebGL.h"
#import "EJConvert.h"
#import <JavaScriptCore/JSTypedArray.h>

// FIXME: use C++ with a template?
#define CREATE_JS_VALUE_TO_ARRAY_FUNC(NAME, TYPE, ARRAY_TYPE) \
TYPE *NAME(JSContextRef ctx, JSValueRef value, GLsizei elementSize, GLsizei *numElements) { \
	if( JSTypedArrayGetType(ctx, value) == ARRAY_TYPE ) { \
		size_t byteLength; \
		TYPE *arrayValue = JSTypedArrayGetDataPtr(ctx, value, &byteLength); \
		GLsizei count = (GLsizei)(byteLength/sizeof(TYPE)); \
		if( arrayValue && count && (count % elementSize) == 0 ) { \
			*numElements = count / elementSize; \
			return arrayValue; \
		} \
	} \
	else if( JSValueIsObject(ctx, value) ) { \
		JSObjectRef jsArray = (JSObjectRef)value; \
		\
		JSStringRef jsLengthName = JSStringCreateWithUTF8CString("length"); \
		GLsizei count = JSValueToNumberFast(ctx, JSObjectGetProperty(ctx, jsArray, jsLengthName, NULL)); \
		JSStringRelease(jsLengthName); \
		\
		if( count && (count % elementSize) == 0 ) { \
			NSMutableData *buffer = [NSMutableData dataWithCapacity:count * sizeof(TYPE)]; \
			TYPE *values = buffer.mutableBytes; \
			for( int i = 0; i < count; i++ ) { \
				values[i] = JSValueToNumberFast(ctx, JSObjectGetPropertyAtIndex(ctx, jsArray, i, NULL)); \
			} \
			*numElements = count / elementSize; \
			return values; \
		} \
	} \
	\
	*numElements = 0; \
	return NULL; \
}

CREATE_JS_VALUE_TO_ARRAY_FUNC( JSValueToGLfloatArray, GLfloat, kJSTypedArrayTypeFloat32Array);
CREATE_JS_VALUE_TO_ARRAY_FUNC( JSValueToGLintArray, GLint, kJSTypedArrayTypeInt32Array);

#undef CREATE_JS_VALUE_TO_ARRAY_FUNC


GLuint EJGetBytesPerPixel(GLenum type, GLenum format) {
	int bytesPerComponent = 0;
	switch( type ) {
		case GL_UNSIGNED_BYTE:
			bytesPerComponent = 1;
			break;
		case GL_FLOAT:
			bytesPerComponent = 4;
			break;
		case GL_HALF_FLOAT_OES:
			bytesPerComponent = 2;
			break;
		case GL_UNSIGNED_SHORT_5_6_5:
		case GL_UNSIGNED_SHORT_4_4_4_4:
		case GL_UNSIGNED_SHORT_5_5_5_1:
			return 2;
	}
	
	switch( format ) {
		case GL_LUMINANCE:
		case GL_ALPHA:
			return 1 * bytesPerComponent;
		case GL_LUMINANCE_ALPHA:
			return 2 * bytesPerComponent;
		case GL_RGB:
			return 3 * bytesPerComponent;
		case GL_RGBA:
			return 4 * bytesPerComponent;
	}
	return 0;
}
