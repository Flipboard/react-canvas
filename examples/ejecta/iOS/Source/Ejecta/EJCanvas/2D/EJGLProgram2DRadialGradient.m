#import "EJGLProgram2DRadialGradient.h"

@implementation EJGLProgram2DRadialGradient
@synthesize inner, diff;

- (void)getUniforms {
	[super getUniforms];
	
	inner = glGetUniformLocation(program, "inner");
	diff = glGetUniformLocation(program, "diff");
}

@end
