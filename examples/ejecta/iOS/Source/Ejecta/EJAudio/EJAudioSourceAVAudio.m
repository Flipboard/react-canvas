#import "EJAudioSourceAVAudio.h"


@implementation EJAudioSourceAVAudio

@synthesize delegate;

- (id)initWithPath:(NSString *)pathp {
	if( self = [super init] ) {
		path = [pathp retain];
		player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
		player.delegate = self;
	}
	return self;
}

- (void)dealloc {
	[path release];
	[player release];
	
	[super dealloc];
}

- (void)play {
	[player play];
}

- (void)pause {
	[player pause];
}

- (void)setLooping:(BOOL)loop {
	player.numberOfLoops = loop ? -1 : 0;
}

- (void)setVolume:(float)volume {
	player.volume = volume;
}

- (void)setPlaybackRate:(float)playbackRate {
	player.enableRate = YES;
	player.rate = playbackRate;
}

- (float)currentTime {
	return player.currentTime;
}

- (void)setCurrentTime:(float)time {
	player.currentTime = time;
}

- (float)duration {
	return player.duration;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	[delegate sourceDidFinishPlaying:self];
}

@end
