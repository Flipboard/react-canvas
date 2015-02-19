#import <Foundation/Foundation.h>
#import "EJGLProgram2D.h"
#import "EJGLProgram2DRadialGradient.h"

#define EJ_OPENGL_VERTEX_BUFFER_SIZE (32 * 1024) // 32kb

@interface EJSharedOpenGLContext : NSObject {
	EJGLProgram2D *glProgram2DFlat;
	EJGLProgram2D *glProgram2DTexture;
	EJGLProgram2D *glProgram2DAlphaTexture;
	EJGLProgram2D *glProgram2DPattern;
	EJGLProgram2DRadialGradient *glProgram2DRadialGradient;
	
	EAGLContext *glContext2D;
	EAGLSharegroup *glSharegroup;
	NSMutableData *vertexBuffer;
}

+ (EJSharedOpenGLContext *)instance;

@property (nonatomic, readonly) EJGLProgram2D *glProgram2DFlat;
@property (nonatomic, readonly) EJGLProgram2D *glProgram2DTexture;
@property (nonatomic, readonly) EJGLProgram2D *glProgram2DAlphaTexture;
@property (nonatomic, readonly) EJGLProgram2D *glProgram2DPattern;
@property (nonatomic, readonly) EJGLProgram2DRadialGradient *glProgram2DRadialGradient;

@property (nonatomic, readonly) EAGLContext *glContext2D;
@property (nonatomic, readonly) EAGLSharegroup *glSharegroup;
@property (nonatomic, readonly) NSMutableData *vertexBuffer;

@end
