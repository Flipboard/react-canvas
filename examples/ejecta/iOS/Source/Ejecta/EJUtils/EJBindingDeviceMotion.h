#import "EJBindingEventedBase.h"
#import "EJJavaScriptView.h"
#import <CoreMotion/CoreMotion.h>

@interface EJBindingDeviceMotion : EJBindingEventedBase<EJDeviceMotionDelegate> {
	CMMotionManager *motionManager;
	JSValueRef params[12];
	float interval;
}

- (void)triggerDeviceMotionEvents;
- (void)triggerEventWithMotion:(CMDeviceMotion *)motion;
- (void)triggerEventWithAccelerometerData:(CMAccelerometerData *)accel;

@end
