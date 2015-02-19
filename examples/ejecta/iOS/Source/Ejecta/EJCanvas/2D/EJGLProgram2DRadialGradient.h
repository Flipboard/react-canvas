#import "EJGLProgram2D.h"

@interface EJGLProgram2DRadialGradient : EJGLProgram2D {
	GLuint inner, diff;
}

@property (nonatomic, readonly) GLuint inner;
@property (nonatomic, readonly) GLuint diff;

@end
