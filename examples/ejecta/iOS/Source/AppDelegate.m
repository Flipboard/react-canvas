
#import "AppDelegate.h"
#import "EJJavaScriptView.h"
@implementation AppDelegate
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Optionally set the idle timer disabled, this prevents the device from sleep when
	// not being interacted with by touch. ie. games with motion control.
	application.idleTimerDisabled = YES;
	
	[self loadViewControllerWithScriptAtPath:@"index.js"];
	
    return YES;
}

- (void)loadViewControllerWithScriptAtPath:(NSString *)path {
	// Release any previous ViewController
	window.frame = UIScreen.mainScreen.bounds;
	window.rootViewController = nil;
	
	EJAppViewController *vc = [[EJAppViewController alloc] initWithScriptAtPath:path];
	window.rootViewController = vc;
	[window makeKeyWindow];
	[vc release];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	window.rootViewController = nil;
	[window release];
    [super dealloc];
}


@end
