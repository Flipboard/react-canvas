#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef enum {
	kEJTextureParamMinFilter,
	kEJTextureParamMagFilter,
	kEJTextureParamWrapS,
	kEJTextureParamWrapT,
	kEJTextureParamLast
} EJTextureParam;

typedef EJTextureParam EJTextureParams[kEJTextureParamLast];


@interface EJTextureStorage : NSObject {
	EJTextureParams params;
	GLuint textureId;
	BOOL immutable;
	NSTimeInterval lastBound;
}
- (id)init;
- (id)initImmutable;
- (void)bindToTarget:(GLenum)target withParams:(EJTextureParam *)newParams;

@property (readonly, nonatomic) GLuint textureId;
@property (readonly, nonatomic) BOOL immutable;
@property (readonly, nonatomic) NSTimeInterval lastBound;

@end
