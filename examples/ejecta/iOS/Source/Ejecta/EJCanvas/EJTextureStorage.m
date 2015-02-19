#import "EJTextureStorage.h"

@implementation EJTextureStorage
@synthesize lastBound;
@synthesize textureId;
@synthesize immutable;

- (id)init {
	if( self = [super init] ) {
		glGenTextures(1, &textureId);
		immutable = NO;
	}
	return self;
}

- (id)initImmutable {
	if( self = [super init] ) {
		glGenTextures(1, &textureId);
		immutable = YES;
	}
	return self;
}

- (void)dealloc {
	if( textureId ) {
		glDeleteTextures(1, &textureId);
	}
	[super dealloc];
}

- (void)bindToTarget:(GLenum)target withParams:(EJTextureParam *)newParams {
	glBindTexture(target, textureId);
	
	// Check if we have to set a param
	if(params[kEJTextureParamMinFilter] != newParams[kEJTextureParamMinFilter]) {
		params[kEJTextureParamMinFilter] = newParams[kEJTextureParamMinFilter];
		glTexParameteri(target, GL_TEXTURE_MIN_FILTER, params[kEJTextureParamMinFilter]);
	}
	if(params[kEJTextureParamMagFilter] != newParams[kEJTextureParamMagFilter]) {
		params[kEJTextureParamMagFilter] = newParams[kEJTextureParamMagFilter];
		glTexParameteri(target, GL_TEXTURE_MAG_FILTER, params[kEJTextureParamMagFilter]);
	}
	if(params[kEJTextureParamWrapS] != newParams[kEJTextureParamWrapS]) {
		params[kEJTextureParamWrapS] = newParams[kEJTextureParamWrapS];
		glTexParameteri(target, GL_TEXTURE_WRAP_S, params[kEJTextureParamWrapS]);
	}
	if(params[kEJTextureParamWrapT] != newParams[kEJTextureParamWrapT]) {
		params[kEJTextureParamWrapT] = newParams[kEJTextureParamWrapT];
		glTexParameteri(target, GL_TEXTURE_WRAP_T, params[kEJTextureParamWrapT]);
	}
	
	lastBound = NSProcessInfo.processInfo.systemUptime;
}

@end

