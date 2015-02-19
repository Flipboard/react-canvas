#import <Foundation/Foundation.h>
#import "EJBindingBase.h"
#import "EJBindingWebGLObjects.h"

typedef struct {
	const char *exposedName;
	const char *internalName;
} EJWebGLExtensionName;

extern const EJWebGLExtensionName EJWebGLExtensions[];
extern const int EJWebGLExtensionsCount;


@interface EJBindingWebGLExtension : EJBindingBase {
	 EJBindingCanvasContextWebGL *webglContext;
}

- (id)initWithWebGLContext:(EJBindingCanvasContextWebGL *)webglContext;

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	webglContext:(EJBindingCanvasContextWebGL *)webglContext;

@end


@interface EJBindingWebGLExtensionEXT_texture_filter_anisotropic : EJBindingWebGLExtension
@end;

@interface EJBindingWebGLExtensionOES_texture_float : EJBindingWebGLExtension
@end;

@interface EJBindingWebGLExtensionOES_texture_half_float : EJBindingWebGLExtension
@end;

@interface EJBindingWebGLExtensionOES_texture_half_float_linear : EJBindingWebGLExtension
@end;

@interface EJBindingWebGLExtensionOES_standard_derivatives : EJBindingWebGLExtension
@end;

@interface EJBindingWebGLExtensionOES_vertex_array_object : EJBindingWebGLExtension
@end;

