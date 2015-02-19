#import "EJBindingBase.h"
#import <GameKit/GameKit.h>

enum {
	kEJGameCenterAutoAuthNeverTried = 0,
	kEJGameCenterAutoAuthFailed = 1,
	kEJGameCenterAutoAuthSucceeded = 2
};

static NSString *kEJGameCenterAutoAuth = @"EJGameCenter.AutoAuth";

@interface EJBindingGameCenter : EJBindingBase <GKGameCenterControllerDelegate> {
	BOOL authed;
	BOOL viewIsActive;
	NSMutableDictionary *achievements;
}

- (void)loadAchievements;
- (void)reportAchievementWithIdentifier:(NSString *)identifier
	percentage:(float)percentage isIncrement:(BOOL)isIncrement
	ctx:(JSContextRef)ctx callback:(JSObjectRef)callback;

@end
