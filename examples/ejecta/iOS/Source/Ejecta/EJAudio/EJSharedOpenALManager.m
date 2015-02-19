#import "EJSharedOpenALManager.h"

@implementation EJSharedOpenALManager

static EJSharedOpenALManager *sharedOpenALManager;

+ (EJSharedOpenALManager *)instance {
	if( !sharedOpenALManager ) {
		sharedOpenALManager = [[[EJSharedOpenALManager alloc] init] autorelease];
	}
    return sharedOpenALManager;
}

- (NSMutableDictionary*)buffers {
	if( !buffers ) {
		// Create a non-retaining Dictionary to hold the cached buffers
		buffers = (NSMutableDictionary*)CFDictionaryCreateMutable(NULL, 8, &kCFCopyStringDictionaryKeyCallBacks, NULL);
		
		// Create the OpenAL device when .buffers is first accessed
		device = alcOpenDevice(NULL);
		if( device ) {
			context = alcCreateContext( device, NULL );
			alcMakeContextCurrent( context );
		}
	}
	
	return buffers;
}

- (void)dealloc {
	sharedOpenALManager = nil;
	[buffers release];
	
	if( context ) { alcDestroyContext( context ); }
	if( device ) { alcCloseDevice( device ); }
	[super dealloc];
}

@end
