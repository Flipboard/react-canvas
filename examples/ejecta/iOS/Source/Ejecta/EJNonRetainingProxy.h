#import <Foundation/Foundation.h>

// "Weak proxy" to avoid retain loops.
// Adapted from http://stackoverflow.com/a/13921278/1525473

@interface EJNonRetainingProxy : NSObject {
	id target;
}

+ (EJNonRetainingProxy *)proxyWithTarget:(id)target;

@end
