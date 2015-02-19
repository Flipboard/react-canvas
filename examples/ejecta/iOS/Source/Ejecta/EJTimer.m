#import "EJTimer.h"
#import "EJJavaScriptView.h"


@implementation EJTimerCollection


- (id)initWithScriptView:(EJJavaScriptView *)scriptViewp {
	if (self = [super init]) {
		scriptView = scriptViewp;
		timers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[timers release];
	[super dealloc];
}

- (int)scheduleCallback:(JSObjectRef)callback interval:(NSTimeInterval)interval repeat:(BOOL)repeat {
	lastId++;
	
	EJTimer *timer = [[EJTimer alloc] initWithScriptView:scriptView callback:callback interval:interval repeat:repeat];
	timers[@(lastId)] = timer;
	[timer release];
	return lastId;
}

- (void)cancelId:(int)timerId {
	[timers removeObjectForKey:@(timerId)];
}

- (void)update {	
	for( NSNumber *timerId in [timers allKeys]) {
		EJTimer *timer = [timers[timerId] retain];
		[timer check];
		
		if( !timer.active ) {
			[timers removeObjectForKey:timerId];
		}
        [timer release];
	}
}

@end



@interface EJTimer()
@property (nonatomic, retain) NSDate *target;
@end


@implementation EJTimer
@synthesize active;

- (id)initWithScriptView:(EJJavaScriptView *)scriptViewp
	callback:(JSObjectRef)callbackp
	interval:(NSTimeInterval)intervalp
	repeat:(BOOL)repeatp
{
	if( self = [super init] ) {
		scriptView = scriptViewp;
		active = true;
		interval = intervalp;
		repeat = repeatp;
		self.target = [NSDate dateWithTimeIntervalSinceNow:interval];
		
		callback = callbackp;
		JSValueProtect(scriptView.jsGlobalContext, callback);
	}
	return self;
}

- (void)dealloc {
	self.target = nil;
	JSValueUnprotectSafe(scriptView.jsGlobalContext, callback);
	[super dealloc];
}

- (void)check {	
	if( active && self.target.timeIntervalSinceNow <= 0 ) {
		[scriptView invokeCallback:callback thisObject:NULL argc:0 argv:NULL];
		
		if( repeat ) {
			self.target = [NSDate dateWithTimeIntervalSinceNow:interval];
		}
		else {
			active = false;
		}
	}
}


@end
