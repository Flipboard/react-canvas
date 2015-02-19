#import "EJBindingDeviceMotion.h"
#import "EJJavaScriptView.h"

@implementation EJBindingDeviceMotion

- (void)createWithJSObject:(JSObjectRef)obj scriptView:(EJJavaScriptView *)view {
	[super createWithJSObject:obj scriptView:view];
	interval = 1.0f/60.0f;
	motionManager = [[CMMotionManager alloc] init];
	
	// Has Gyro? (iPhone4 and newer)
	if( motionManager.isDeviceMotionAvailable ) {
		motionManager.deviceMotionUpdateInterval = interval;
		[motionManager startDeviceMotionUpdates];
	}
	
	// Only basic accelerometer data
	else {
		motionManager.accelerometerUpdateInterval = interval;
		[motionManager startAccelerometerUpdates];
	}
	
	scriptView.deviceMotionDelegate	= self;
}

- (void)prepareGarbageCollection {
	[motionManager stopDeviceMotionUpdates];
	[motionManager stopAccelerometerUpdates];
}

- (void)dealloc {
	[motionManager release];
	[super dealloc];
}


static const float g = 9.80665;
static const float radToDeg = (180/M_PI);

- (void)triggerEventWithMotion:(CMDeviceMotion *)motion {
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	// accelerationIncludingGravity {x, y, z}
	params[0] = JSValueMakeNumber(ctx, (motion.userAcceleration.x + motion.gravity.x) * g);
	params[1] = JSValueMakeNumber(ctx, (motion.userAcceleration.y + motion.gravity.y) * g);
	params[2] = JSValueMakeNumber(ctx, (motion.userAcceleration.z + motion.gravity.z) * g);
	
	// acceleration {x, y, z}
	params[3] = JSValueMakeNumber(ctx, motion.userAcceleration.x * g);
	params[4] = JSValueMakeNumber(ctx, motion.userAcceleration.y * g);
	params[5] = JSValueMakeNumber(ctx, motion.userAcceleration.z * g);
	
	// rotation rate {alpha, beta, gamma}
	params[6] = JSValueMakeNumber(ctx, motion.rotationRate.x * radToDeg);
	params[7] = JSValueMakeNumber(ctx, motion.rotationRate.y * radToDeg);
	params[8] = JSValueMakeNumber(ctx, motion.rotationRate.z * radToDeg);
	
	// orientation {alpha, beta, gamma}
	params[9] = JSValueMakeNumber(ctx, motion.attitude.yaw * radToDeg);
	params[10] = JSValueMakeNumber(ctx, motion.attitude.pitch * radToDeg);
	params[11] = JSValueMakeNumber(ctx, motion.attitude.roll * radToDeg);
	
	[self triggerEvent:@"devicemotion" argc:12 argv:params];
}

- (void)triggerEventWithAccelerometerData:(CMAccelerometerData *)accel {
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	// accelerationIncludingGravity {x, y, z}
	params[0] = JSValueMakeNumber(ctx, accel.acceleration.x * g);
	params[1] = JSValueMakeNumber(ctx, accel.acceleration.y * g);
	params[2] = JSValueMakeNumber(ctx, accel.acceleration.z * g);
	
	[self triggerEvent:@"acceleration" argc:3 argv:params];
}

- (void)triggerDeviceMotionEvents {
	if( motionManager.isDeviceMotionAvailable ) {
		[self triggerEventWithMotion:motionManager.deviceMotion];
	}
	else {
		[self triggerEventWithAccelerometerData:motionManager.accelerometerData];
	}
}

EJ_BIND_GET(interval, ctx) {
	return JSValueMakeNumber(ctx, roundf(interval*1000)); // update interval in ms
}

EJ_BIND_EVENT(devicemotion);
EJ_BIND_EVENT(acceleration);

@end
