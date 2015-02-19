#import <Foundation/Foundation.h>
#import "EJBindingBase.h"
#import "EJCanvasContextWebGL.h"
#import "EJTexture.h"

#define GL_UNPACK_FLIP_Y_WEBGL 0x9240
#define GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL 0x9241
#define GL_CONTEXT_LOST_WEBGL 0x9242
#define GL_UNPACK_COLORSPACE_CONVERSION_WEBGL 0x9243
#define GL_BROWSER_DEFAULT_WEBGL 0x9244

#define GL_DEPTH_STENCIL_ATTACHMENT 0x821A

#define EJ_CANVAS_MAX_TEXTURE_UNITS 8
#define EJ_BUFFER_OFFSET(i) ((char *)NULL + (i))

#define EJ_BIND_CONST_GL(NAME) EJ_BIND_CONST(NAME, GL_##NAME)

typedef struct {
	EJTexture *texture;
	JSObjectRef jsTexture;
	EJTexture *cubeMap;
	JSObjectRef jsCubeMap;
} EJCanvasContextTextureUnit;

@class EJJavaScriptView;
@interface EJBindingCanvasContextWebGL : EJBindingBase {
	
	BOOL unpackFlipY;
	BOOL premultiplyAlpha;
	
	JSObjectRef jsCanvas;
	EJCanvasContextWebGL *renderingContext;
	
	NSMutableDictionary *renderbuffers;
	NSMutableDictionary *framebuffers;
	NSMutableDictionary *buffers;
	NSMutableDictionary *textures;
	NSMutableDictionary *programs;
	NSMutableDictionary *shaders;
	
    NSMutableDictionary *extensions;
    
    NSMutableDictionary *vertexArrays;
    
	EJCanvasContextTextureUnit textureUnits[EJ_CANVAS_MAX_TEXTURE_UNITS];
	EJCanvasContextTextureUnit *activeTexture;
}

- (id)initWithCanvas:(JSObjectRef)canvas renderingContext:(EJCanvasContextWebGL *)renderingContextp;

- (void)deleteRenderbuffer:(GLuint)renderbuffer;
- (void)deleteFramebuffer:(GLuint)framebuffer;
- (void)deleteBuffer:(GLuint)buffer;
- (void)deleteTexture:(GLuint)texture;
- (void)deleteProgram:(GLuint)program;
- (void)deleteShader:(GLuint)shader;

- (void)addVertexArray:(GLuint)vertexArray obj:(JSObjectRef)objp;
- (void)deleteVertexArray:(GLuint)vertexArray;

@property (readonly, nonatomic) EJCanvasContextWebGL *renderingContext;

@end
