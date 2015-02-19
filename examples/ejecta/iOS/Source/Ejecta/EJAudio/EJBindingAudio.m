#import "EJBindingAudio.h"
#import "EJJavaScriptView.h"
#import "EJNonRetainingProxy.h"

@implementation EJBindingAudio

@synthesize loop, ended, volume;
@synthesize path;
@synthesize preload;

- (id)initWithContext:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctx argc:argc argv:argv] ) {
		volume = 1;
		paused = true;
		preload = kEJAudioPreloadNone;
		
		if( argc > 0 ) {
			[self setSourcePath:JSValueToNSString(ctx, argv[0])];
		}
	}
	return self;
}

- (void)dealloc {
	[loadCallback cancel];
	[loadCallback release];
	
	source.delegate = nil;
	[source release];
	[path release];
	[super dealloc];
}

- (void)setSourcePath:(NSString *)pathp {
	if( !path || ![path isEqualToString:pathp] ) {
		[path release];
		[source release];
		source = NULL;
		
		path = [pathp retain];
		if( preload != kEJAudioPreloadNone ) {
			[self load];
		}
	}
}

- (void)load {
	if( source || !path || loading ) { return; }
	
	// This will begin loading the sound in a background thread
	loading = YES;
	
	// Protect this Audio object from garbage collection, as its callback function
	// may be the only thing holding on to it
	JSValueProtect(scriptView.jsGlobalContext, jsObject);
	
	
	EJNonRetainingProxy *proxy = [EJNonRetainingProxy proxyWithTarget:self];
	
	loadCallback = [[NSInvocationOperation alloc]
		initWithTarget:proxy selector:@selector(endLoad) object:nil];
	
	NSOperation *loadOp = [[NSInvocationOperation alloc]
		initWithTarget:proxy selector:@selector(backgroundLoad) object:nil];
		
	[scriptView.backgroundQueue addOperation:loadOp];
	[loadOp release];
}

- (void)prepareGarbageCollection {
	[loadCallback cancel];
}

- (void)backgroundLoad {
	// Decide whether to load the sound as OpenAL or AVAudioPlayer source
	NSString *fullPath = [scriptView pathForResource:path];
	unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil] fileSize];
	
	if( size <= EJ_AUDIO_OPENAL_MAX_SIZE ) {
		NSLog(@"Loading Sound(OpenAL): %@", path);
		source = [[EJAudioSourceOpenAL alloc] initWithPath:fullPath];
	}
	else {
		NSLog(@"Loading Sound(AVAudio): %@", path);
		source = [[EJAudioSourceAVAudio alloc] initWithPath:fullPath];
	}

	[NSOperationQueue.mainQueue addOperation:loadCallback];
}

- (void)endLoad {
	[loadCallback release];
	loadCallback = nil;
		
	source.delegate = self;
	[source setLooping:loop];
	[source setVolume:(muted ? 0.0 : volume)];
	
	if( playAfterLoad ) {
		[source play];
		paused = false;
	}
	
	loading = NO;
	[self triggerEvent:@"canplaythrough"];
	[self triggerEvent:@"loadedmetadata"];
	
	JSValueUnprotectSafe(scriptView.jsGlobalContext, jsObject);
}

- (void)sourceDidFinishPlaying:(NSObject<EJAudioSource> *)source {
	ended = true;
	[self triggerEvent:@"ended"];
}

- (void)setPreload:(EJAudioPreload)preloadp {
	preload = preloadp;
	if( preload != kEJAudioPreloadNone ) {
		[self load];
	}
}


EJ_BIND_FUNCTION(play, ctx, argc, argv) {
	if( !source ) {
		playAfterLoad = YES;
		[self load];
	}
	else {
		[source play];
		paused = false;
		ended = false;
	}
	return NULL;
}

EJ_BIND_FUNCTION(pause, ctx, argc, argv) {
	if( !source ) {
		playAfterLoad = NO;
	}
	else {
		paused = true;
		[source pause];
	}
	return NULL;
}

EJ_BIND_FUNCTION(load, ctx, argc, argv) {
	[self load];
	return NULL;
}

EJ_BIND_FUNCTION(canPlayType, ctx, argc, argv) {
	if( argc != 1 ) return NSStringToJSValue(ctx, @"");
	
	NSString *mime = JSValueToNSString(ctx, argv[0]);
	if( 
		[mime hasPrefix:@"audio/x-caf"] ||
		[mime hasPrefix:@"audio/mpeg"] ||
		[mime hasPrefix:@"audio/mp4"]
	) {
		return NSStringToJSValue(ctx, @"probably");
	}
	return NSStringToJSValue(ctx, @"");
}

EJ_BIND_FUNCTION(cloneNode, ctx, argc, argv) {
	EJBindingAudio *audio = [[EJBindingAudio alloc] initWithContext:ctx argc:0 argv:NULL];
	JSObjectRef clone = [EJBindingAudio createJSObjectWithContext:ctx scriptView:scriptView instance:audio];
	
	audio.loop = loop;
	audio.volume = volume;
	audio.preload = preload;
	audio.path = path;
	
	if( source ) {
		// If the source for this audio element was loaded,
		// load it for the cloned one as well.
		[audio load];
	}
	
	[audio release];
	return clone;
}

EJ_BIND_GET(duration, ctx) {
	return JSValueMakeNumber(ctx, source.duration);
}

EJ_BIND_GET(loop, ctx) {
	return JSValueMakeBoolean( ctx, loop );
}

EJ_BIND_SET(loop, ctx, value) {
	loop = JSValueToBoolean(ctx, value);
	[source setLooping:loop];
}

EJ_BIND_GET(volume, ctx) {
	return JSValueMakeNumber( ctx, volume );
}

EJ_BIND_SET(volume, ctx, value) {
	volume = MIN(1,MAX(JSValueToNumberFast(ctx, value),0));
	[source setVolume:(muted ? 0.0 : volume)];
}

EJ_BIND_GET(playbackRate, ctx) {
	return JSValueMakeNumber( ctx, playbackRate );
}

EJ_BIND_SET(playbackRate, ctx, value) {
	playbackRate = MIN(2,MAX(JSValueToNumberFast(ctx, value),0.5));
	[source setPlaybackRate:playbackRate];
}

EJ_BIND_GET(currentTime, ctx) {
	return JSValueMakeNumber( ctx, source ? source.currentTime : 0 );
}

EJ_BIND_SET(currentTime, ctx, value) {
	[self load];
	source.currentTime = JSValueToNumberFast(ctx, value);
}

EJ_BIND_GET(src, ctx) {
	return path ? NSStringToJSValue(ctx, path) : NULL;
}

EJ_BIND_SET(src, ctx, value) {
	[self setSourcePath:JSValueToNSString(ctx, value)];
	if( preload != kEJAudioPreloadNone ) {
		[self load];
	}
}

EJ_BIND_GET(muted, ctx) {
	return JSValueMakeBoolean(ctx, muted);
}

EJ_BIND_SET(muted, ctx, value) {
	muted = JSValueToBoolean(ctx, value);
	[source setVolume:(muted ? 0.0 : volume)];
}

EJ_BIND_GET(ended, ctx) {
	return JSValueMakeBoolean(ctx, ended);
}

EJ_BIND_GET(paused, ctx) {
	return JSValueMakeBoolean(ctx, paused);
}

EJ_BIND_ENUM(preload, self.preload,
	"none",		// kEJAudioPreloadNone
	"metadata", // kEJAudioPreloadMetadata
	"auto"		// kEJAudioPreloadAuto
);

EJ_BIND_GET(readyState, ctx) {
	EJAudioReadyState state = kEJAudioHaveNothing;
	if( source ) {
		state = ended ? kEJAudioHaveCurrentData : kEJAudioHaveEnoughData;
	}
	return JSValueMakeNumber(ctx, state);
}


EJ_BIND_EVENT(loadedmetadata);
EJ_BIND_EVENT(canplaythrough);
EJ_BIND_EVENT(ended);

EJ_BIND_CONST(nodeName, "AUDIO");

EJ_BIND_CONST(HAVE_NOTHING, kEJAudioHaveNothing);
EJ_BIND_CONST(HAVE_METADATA, kEJAudioHaveMetadata);
EJ_BIND_CONST(HAVE_CURRENT_DATA, kEJAudioHaveCurrentData);
EJ_BIND_CONST(HAVE_FUTURE_DATA, kEJAudioHaveFutureData);
EJ_BIND_CONST(HAVE_ENOUGH_DATA, kEJAudioHaveEnoughData);

@end
