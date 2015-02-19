#import <Foundation/Foundation.h>
#import "iAd/iAd.h"
#import "EJBindingEventedBase.h"


@interface EJBindingAdBanner : EJBindingEventedBase <ADBannerViewDelegate> {
	ADBannerView *banner;
	BOOL isAtBottom, wantsToShow, isReady;
}

@end
