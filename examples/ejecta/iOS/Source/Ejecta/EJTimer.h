#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class EJJavaScriptView;

@interface EJTimerCollection : NSObject {
	NSMutableDictionary *timers;
	int lastId;
	EJJavaScriptView *scriptView;
}

- (id)initWithScriptView:(EJJavaScriptView *)scriptView;
- (int)scheduleCallback:(JSObjectRef)callback interval:(NSTimeInterval)interval repeat:(BOOL)repeat;
- (void)cancelId:(int)timerId;
- (void)update;

@end


@interface EJTimer : NSObject {
	NSTimeInterval interval;
	JSObjectRef callback;
	BOOL active, repeat;
	EJJavaScriptView *scriptView;
}

- (id)initWithScriptView:(EJJavaScriptView *)scriptViewp
	callback:(JSObjectRef)callbackp
	interval:(NSTimeInterval)intervalp
	repeat:(BOOL)repeatp;
- (void)check;

@property (readonly) BOOL active;

@end
