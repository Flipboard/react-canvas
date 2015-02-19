#import <objc/runtime.h>

#import "EJAppViewController.h"
#import "EJJavaScriptView.h"

@implementation EJAppViewController

- (id)initWithScriptAtPath:(NSString *)pathp {
	if( self = [super init] ) {
		path = [pathp retain];
        if ([[NSBundle mainBundle] infoDictionary][@"UIInterfaceOrientation"])
        {
            landscapeMode = [[[NSBundle mainBundle] infoDictionary][@"UIInterfaceOrientation"] hasPrefix:@"UIInterfaceOrientationLandscape"];
        }
        else
        {
            landscapeMode = [[[NSBundle mainBundle] infoDictionary][@"UISupportedInterfaceOrientations"][0] hasPrefix:@"UIInterfaceOrientationLandscape"];
        }
	}
	return self;
}

- (void)dealloc {
	self.view = nil;
	[path release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	[(EJJavaScriptView *)self.view clearCaches];
	[super didReceiveMemoryWarning];
}

- (void)loadView {
	CGRect frame = UIScreen.mainScreen.bounds;

	// iOS pre 8.0 doesn't rotate the frame size in landscape mode, so we have to
	// do it ourselfs
	if( landscapeMode && EJECTA_SYSTEM_VERSION_LESS_THAN(@"8.0") ) {
		frame.size = CGSizeMake(frame.size.height, frame.size.width);
	}
	
	EJJavaScriptView *view = [[EJJavaScriptView alloc] initWithFrame:frame];
	self.view = view;
	
	[view loadScriptAtPath:path];
	[view release];
}

- (NSUInteger)supportedInterfaceOrientations {
	if( landscapeMode ) {
		// Allow Landscape Left and Right
		return UIInterfaceOrientationMaskLandscape;
	}
	else {
		if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
			// Allow Portrait UpsideDown on iPad
			return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
		}
		else {
			// Only Allow Portrait
			return UIInterfaceOrientationMaskPortrait;
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	// Deprecated in iOS6 - supportedInterfaceOrientations is the new way to do this
	// We just use the mask returned by supportedInterfaceOrientations here to check if
	// this particular orientation is allowed.
	return ( self.supportedInterfaceOrientations & (1 << orientation) );
}

@end
