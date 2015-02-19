#import "EJAudioSourceOpenAL.h"
#import "EJAppViewController.h"

@implementation EJAudioSourceOpenAL

@synthesize delegate;

- (id)initWithPath:(NSString *)pathp {
	if( self = [super init] ) {
		path = [pathp retain];
		
		buffer = [[EJOpenALBuffer cachedBufferWithPath:pathp] retain];
		
		alGenSources(1, &sourceId); 
		alSourcei(sourceId, AL_BUFFER, buffer.bufferId);
		alSourcef(sourceId, AL_PITCH, 1.0f);
		alSourcef(sourceId, AL_GAIN, 1.0f);
	}
	return self;
}

- (void)dealloc {
	if( sourceId ) {
		alDeleteSources(1, &sourceId);
	}
	
	[buffer release];
	[path release];
	[endTimer invalidate];
	
	[super dealloc];
}

- (void)play {
	alSourcePlay( sourceId );
	
	[endTimer invalidate];
	
	float targetTime = buffer.duration - self.currentTime;
	endTimer = [NSTimer scheduledTimerWithTimeInterval:targetTime
		target:self selector:@selector(ended:) userInfo:nil repeats:NO];
}

- (void)pause {
	alSourceStop( sourceId );
	[endTimer invalidate];
	endTimer = nil;
}

- (void)setLooping:(BOOL)loop {
	looping = loop;
	alSourcei( sourceId, AL_LOOPING, loop ? AL_TRUE : AL_FALSE );
}

- (void)setVolume:(float)volume {
	alSourcef( sourceId, AL_GAIN, volume );
}

- (void)setPlaybackRate:(float)playbackRate {
	alSourcef( sourceId, AL_PITCH, playbackRate);
}

- (float)currentTime {
	float time;
	alGetSourcef( sourceId, AL_SEC_OFFSET, &time );
	return time;
}

- (void)setCurrentTime:(float)time {
	alSourcef( sourceId, AL_SEC_OFFSET, time );
}

- (float)duration {
	return buffer.duration;
}

- (void)ended:(NSTimer *)timer {
	endTimer = nil;
	if( !looping ) {
		[delegate sourceDidFinishPlaying:self];
	}
}

@end
