#import "EJBindingEventedBase.h"
#import "EJJavaScriptView.h"

@interface EJBindingWindowEvents : EJBindingEventedBase <EJWindowEventsDelegate>

- (void)pause;
- (void)resume;
- (void)resize;

@end
