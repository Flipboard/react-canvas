#import "EJNonRetainingProxy.h"

@implementation EJNonRetainingProxy
+ (EJNonRetainingProxy *)proxyWithTarget:(id)target {
    EJNonRetainingProxy *proxy = [[[self alloc] init] autorelease];
    proxy->target = target;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
	return [target methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)sel {
    return [target respondsToSelector:sel] || [super respondsToSelector:sel];
}

- (id)forwardingTargetForSelector:(SEL)sel {
    return target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if( [target respondsToSelector:invocation.selector] ) {
        [invocation invokeWithTarget:target];
	}
    else {
		[super forwardInvocation:invocation];
	}
}

@end
