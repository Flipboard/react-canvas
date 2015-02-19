#import "EJBindingEventedBase.h"
#import <MediaPlayer/MediaPlayer.h>

typedef enum {
	kEJVideoScalingModeNone,
	kEJVideoScalingModeAspectFit,
	kEJVideoScalingModeAspectFill,
	kEJVideoScalingModeFill
} EJVideoScalingMode;

@interface EJBindingVideo : EJBindingEventedBase <UIGestureRecognizerDelegate> {
	NSString *path;
	BOOL loaded;
	BOOL showControls;
	EJVideoScalingMode scalingMode;
	MPMoviePlayerController *player;
}

@end
