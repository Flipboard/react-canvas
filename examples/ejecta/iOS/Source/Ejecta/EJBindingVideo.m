#import "EJBindingVideo.h"

// Better be safe than sorry
static const EJVideoScalingMode EJVideoToMPMovieScalingMode[] = {
	[kEJVideoScalingModeNone] = MPMovieScalingModeNone,
	[kEJVideoScalingModeAspectFit] = MPMovieScalingModeAspectFit,
	[kEJVideoScalingModeAspectFill] = MPMovieScalingModeAspectFill,
	[kEJVideoScalingModeFill] = MPMovieScalingModeFill
};


@implementation EJBindingVideo

- (id)initWithContext:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctx argc:argc argv:argv] ) {
		scalingMode = kEJVideoScalingModeAspectFill;
	}
	return self;
}

- (void)prepareGarbageCollection {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
	[player stop];
	[player.view removeFromSuperview];
	[player release];
	[path release];
	[super dealloc];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

EJ_BIND_ENUM(scalingMode, scalingMode,
	"none",			// kEJVideoScalingModeNone,
	"aspect-fit",	// kEJVideoScalingModeAspectFit,
	"aspect-fill",	// kEJVideoScalingModeAspectFill,
	"fill"			// kEJVideoScalingModeFill
);

EJ_BIND_GET(duration, ctx) {
	return JSValueMakeNumber(ctx, player.duration);
}

EJ_BIND_GET(loop, ctx) {
	return JSValueMakeBoolean( ctx, (player.repeatMode == MPMovieRepeatModeNone) );
}

EJ_BIND_SET(loop, ctx, value) {
	player.repeatMode = MPMovieRepeatModeOne;
}

EJ_BIND_GET(controls, ctx) {
	return JSValueMakeBoolean( ctx, showControls );
}

EJ_BIND_SET(controls, ctx, value) {
	showControls = JSValueToNumberFast(ctx, value);
	player.controlStyle = showControls ? MPMovieControlStyleEmbedded : MPMovieControlStyleNone;
}

EJ_BIND_GET(currentTime, ctx) {
	return JSValueMakeNumber( ctx, player.currentPlaybackTime );
}

EJ_BIND_SET(currentTime, ctx, value) {
	player.currentPlaybackTime = JSValueToNumberFast(ctx, value);
}

EJ_BIND_GET(src, ctx) {
	return path ? NSStringToJSValue(ctx, path) : NULL;
}

EJ_BIND_SET(src, ctx, value) {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[player stop];
	[player.view removeFromSuperview];
	[player release];
	player = nil;
	
	[path release];
	path = nil;
	
	path = [JSValueToNSString(ctx, value) retain];
	
	NSURL *url = [NSURL URLWithString:path];
	if( !url.host ) {
		// No host? Assume we have a local file
		url = [NSURL fileURLWithPath:[scriptView pathForResource:path]];
	}
	
	player = [[MPMoviePlayerController alloc] initWithContentURL:url];
	player.controlStyle = MPMovieControlStyleNone;
    player.movieSourceType = MPMovieSourceTypeFile;
	player.shouldAutoplay = NO;
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
		initWithTarget:self action:@selector(didTap:)];
	tapGesture.delegate = self;
	tapGesture.numberOfTapsRequired = 1;
	[player.view addGestureRecognizer:tapGesture];
	[tapGesture release];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(preparedToPlayChange:)
		name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(didFinish:)
		name:MPMoviePlayerPlaybackDidFinishNotification
		object:player];
	
	[player prepareToPlay];
}

- (void)preparedToPlayChange:(MPMoviePlayerController *)moviePlayer {
	if( player.isPreparedToPlay && !loaded ) {
		loaded = YES;
		[self triggerEvent:@"canplaythrough"];
		[self triggerEvent:@"loadedmetadata"];
	}
}

- (void)didTap:(UIGestureRecognizer *)gestureRecognizer {
	[self triggerEvent:@"click"];
}

- (void)didFinish:(MPMoviePlayerController *)moviePlayer {
	player.fullscreen = NO;
	[player.view removeFromSuperview];
	[self triggerEvent:@"ended"];
}

EJ_BIND_GET(ended, ctx) {
	return JSValueMakeBoolean(ctx, player.playbackState == MPMoviePlaybackStateStopped);
}

EJ_BIND_GET(paused, ctx) {
	return JSValueMakeBoolean(ctx, (player.playbackState != MPMoviePlaybackStatePlaying));
}

EJ_BIND_FUNCTION(play, ctx, argc, argv) {
	if( player.playbackState == MPMoviePlaybackStatePlaying ) {
		// Already playing. Nothing to do here.
		return NULL;
	}
	
	player.view.frame = scriptView.bounds;
	[scriptView addSubview:player.view];
	player.scalingMode = EJVideoToMPMovieScalingMode[scalingMode];
	player.controlStyle = showControls ? MPMovieControlStyleEmbedded : MPMovieControlStyleNone;
	[player play];
	
	return NULL;
}

EJ_BIND_FUNCTION(pause, ctx, argc, argv) {
	[player pause];
	player.fullscreen = NO;
	[player.view removeFromSuperview];
	return NULL;
}

EJ_BIND_FUNCTION(load, ctx, argc, argv) {
	[player prepareToPlay];
	return NULL;
}

EJ_BIND_FUNCTION(canPlayType, ctx, argc, argv) {
	if( argc != 1 ) return NSStringToJSValue(ctx, @"");
	
	NSString *mime = JSValueToNSString(ctx, argv[0]);
	if( [mime hasPrefix:@"video/mp4"] ) {
		return NSStringToJSValue(ctx, @"probably");
	}
	return NSStringToJSValue(ctx, @"");
}

EJ_BIND_EVENT(canplaythrough);
EJ_BIND_EVENT(loadedmetadata);
EJ_BIND_EVENT(ended);
EJ_BIND_EVENT(click);

EJ_BIND_CONST(nodeName, "VIDEO");

@end
