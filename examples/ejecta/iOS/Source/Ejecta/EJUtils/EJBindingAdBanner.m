#import "EJBindingAdBanner.h"
#import "EJJavaScriptView.h"

@implementation EJBindingAdBanner

- (void)createWithJSObject:(JSObjectRef)obj scriptView:(EJJavaScriptView *)view {
	[super createWithJSObject:obj scriptView:view];
	
	isAtBottom = NO;
	wantsToShow = NO;
	isReady = NO;
	
	banner = [[ADBannerView alloc] initWithFrame:CGRectZero];
	banner.delegate = self;
	banner.hidden = YES;
	banner.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	[scriptView addSubview:banner];
	NSLog(@"AdBanner: init at y %f", banner.frame.origin.y);
}

- (void)dealloc {
	[banner removeFromSuperview];
	[banner release];
	[super dealloc];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)theBanner {
	NSLog(@"AdBanner: Ad loaded");
	isReady = YES;
	if( wantsToShow ) {
		[scriptView bringSubviewToFront:banner];
		banner.hidden = NO;
	}
	[self triggerEvent:@"load"];
}

- (void)bannerView:(ADBannerView *)theBanner didFailToReceiveAdWithError:(NSError *)error {
	NSLog(@"AdBanner: Failed to receive Ad. Error: %ld - %@", (long)error.code, error.localizedDescription);
	[self triggerEvent:@"error"];
	banner.hidden = YES;
}

EJ_BIND_GET( isReady, ctx ) {
	return JSValueMakeBoolean(ctx, isReady);
}

EJ_BIND_GET( isAtBottom, ctx ) {
	return JSValueMakeBoolean(ctx, isAtBottom);
}

EJ_BIND_SET( isAtBottom, ctx, value ) {
	isAtBottom = JSValueToBoolean(ctx, value);
	
	CGRect frame = banner.frame;
	frame.origin.y = isAtBottom
		? scriptView.bounds.size.height - frame.size.height
		: 0;
		
	banner.frame = frame;
}

EJ_BIND_FUNCTION(hide, ctx, argc, argv ) {
	banner.hidden = YES;
	wantsToShow = NO;
	return NULL;
}

EJ_BIND_FUNCTION(show, ctx, argc, argv ) {
	wantsToShow = YES;
	if( isReady ) {
		[scriptView bringSubviewToFront:banner];
		banner.hidden = NO;
	}
	return NULL;
}

EJ_BIND_EVENT(load);
EJ_BIND_EVENT(error);

@end
