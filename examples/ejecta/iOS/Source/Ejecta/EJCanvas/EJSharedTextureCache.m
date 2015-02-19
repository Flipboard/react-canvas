#import "EJSharedTextureCache.h"
#import "EJTexture.h"

@implementation EJSharedTextureCache
@synthesize textures;

static EJSharedTextureCache *sharedTextureCache;

+ (EJSharedTextureCache *)instance {
	if( !sharedTextureCache ) {
		sharedTextureCache = [[[EJSharedTextureCache alloc] init] autorelease];
	}
    return sharedTextureCache;
}

- (id)init {
	if( self = [super init] ) {
		// Create a non-retaining Dictionary to hold the cached textures
		textures = (NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 8, &kCFCopyStringDictionaryKeyCallBacks, NULL);
	}
	return self;
}

- (void)releaseStoragesOlderThan:(NSTimeInterval)seconds {
	NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
	for( NSString *key in textures ) {
		EJTexture *texture = [textures objectForKey:key];
		if( now - texture.lastUsed > seconds ) {
			[texture maybeReleaseStorage];
		}
	}
}

- (void)dealloc {
	sharedTextureCache = nil;
	[textures release];
	[premultiplyTable release];
	[unPremultiplyTable release];
	[super dealloc];
}


// Lookup tables for fast [un]premultiplied alpha color values
// From https://bugzilla.mozilla.org/show_bug.cgi?id=662130

- (NSData *)premultiplyTable {
	if( !premultiplyTable ) {
		premultiplyTable = [[NSMutableData alloc] initWithLength:256*256];
		
		unsigned char *data = premultiplyTable.mutableBytes;
		for( int a = 0; a <= 255; a++ ) {
			for( int c = 0; c <= 255; c++ ) {
				data[a*256+c] = (a * c + 254) / 255;
			}
		}
	}
	
	return premultiplyTable;
}

- (NSData *)unPremultiplyTable {
	if( !unPremultiplyTable ) {
		unPremultiplyTable = [[NSMutableData alloc] initWithLength:256*256];
		
		unsigned char *data = unPremultiplyTable.mutableBytes;
		// a == 0 case
		for( int c = 0; c <= 255; c++ ) {
			data[c] = c;
		}

		for( int a = 1; a <= 255; a++ ) {
			for( int c = 0; c <= 255; c++ ) {
				data[a*256+c] = (c * 255) / a;
			}
		}
	}
	
	return unPremultiplyTable;
}



@end
