#import "EJSharedOpenGLContext.h"
#import "EJCanvas/2D/EJCanvasShaders.h"

@implementation EJSharedOpenGLContext

@synthesize glProgram2DFlat;
@synthesize glProgram2DTexture;
@synthesize glProgram2DAlphaTexture;
@synthesize glProgram2DPattern;
@synthesize glProgram2DRadialGradient;
@synthesize glContext2D;
@synthesize glSharegroup;

static EJSharedOpenGLContext *sharedOpenGLContext;
+ (EJSharedOpenGLContext *)instance {
	if( !sharedOpenGLContext ) {
		sharedOpenGLContext = [[[EJSharedOpenGLContext alloc] init] autorelease];
	}
    return sharedOpenGLContext;
}

- (id)init {
	if( self = [super init] ) {
		glContext2D = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		glSharegroup = glContext2D.sharegroup;
	}
	return self;
}

- (void)dealloc {
	sharedOpenGLContext = nil;
	
	[glProgram2DFlat release];
	[glProgram2DTexture release];
	[glProgram2DAlphaTexture release];
	[glProgram2DPattern release];
	[glProgram2DRadialGradient release];
	[glContext2D release];
	[vertexBuffer release];
	
	[EAGLContext setCurrentContext:nil];
	[super dealloc];
}

- (NSMutableData *)vertexBuffer {
	if( !vertexBuffer ) {
		vertexBuffer = [[NSMutableData alloc] initWithLength:EJ_OPENGL_VERTEX_BUFFER_SIZE];
	}
	return vertexBuffer;
}

#define EJ_GL_PROGRAM_GETTER(TYPE, NAME) \
	- (TYPE *)glProgram2D##NAME { \
		if( !glProgram2D##NAME ) { \
			glProgram2D##NAME = [[TYPE alloc] initWithVertexShader:EJShaderVertex fragmentShader:EJShader##NAME]; \
		} \
	return glProgram2D##NAME; \
	}

EJ_GL_PROGRAM_GETTER(EJGLProgram2D, Flat);
EJ_GL_PROGRAM_GETTER(EJGLProgram2D, Texture);
EJ_GL_PROGRAM_GETTER(EJGLProgram2D, AlphaTexture);
EJ_GL_PROGRAM_GETTER(EJGLProgram2D, Pattern);
EJ_GL_PROGRAM_GETTER(EJGLProgram2DRadialGradient, RadialGradient);

#undef EJ_GL_PROGRAM_GETTER

@end
