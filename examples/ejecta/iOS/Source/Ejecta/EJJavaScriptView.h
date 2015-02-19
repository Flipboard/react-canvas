#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "EJConvert.h"
#import "EJCanvasContext.h"
#import "EJPresentable.h"

#import "EJSharedOpenALManager.h"
#import "EJSharedTextureCache.h"
#import "EJSharedOpenGLContext.h"
#import "EJNonRetainingProxy.h"

#define EJECTA_VERSION @"1.5"
#define EJECTA_DEFAULT_APP_FOLDER @"App/"

#define EJECTA_BOOT_JS @"../Ejecta.js"

#define EJECTA_SYSTEM_VERSION_LESS_THAN(v) \
	([UIDevice.currentDevice.systemVersion compare:v options:NSNumericSearch] == NSOrderedAscending)


@protocol EJTouchDelegate
- (void)triggerEvent:(NSString *)name all:(NSSet *)all changed:(NSSet *)changed remaining:(NSSet *)remaining;
@end

@protocol EJDeviceMotionDelegate
- (void)triggerDeviceMotionEvents;
@end

@protocol EJWindowEventsDelegate
- (void)resume;
- (void)pause;
- (void)resize;
@end

@class EJTimerCollection;
@class EJClassLoader;

@interface EJJavaScriptView : UIView {
	CGSize oldSize;
	NSString *appFolder;
	
	BOOL pauseOnEnterBackground;
	BOOL hasScreenCanvas;

	BOOL isPaused;
	
	EJNonRetainingProxy	*proxy;

	JSGlobalContextRef jsGlobalContext;
	EJClassLoader *classLoader;

	EJTimerCollection *timers;

    NSMutableDictionary *animationFrameCallbacks;
    NSMutableArray *canceledAnimationFrameCallbacks;
	
	EJSharedOpenGLContext *openGLContext;
	EJSharedTextureCache *textureCache;
	EJSharedOpenALManager *openALManager;
	
	EJCanvasContext *currentRenderingContext;
	EAGLContext *glCurrentContext;
	
	CADisplayLink *displayLink;
    NSTimeInterval baseTime;
    int animationFrameCounter;
    int animationFrameCallbackCounter;
    BOOL runningDisplayLinkUpdate;

	NSObject<EJWindowEventsDelegate> *windowEventsDelegate;
	NSObject<EJTouchDelegate> *touchDelegate;
	NSObject<EJDeviceMotionDelegate> *deviceMotionDelegate;
	EJCanvasContext<EJPresentable> *screenRenderingContext;

	NSOperationQueue *backgroundQueue;
	JSClassRef jsBlockFunctionClass;
	
	// Public for fast access in bound functions
	@public JSValueRef jsUndefined;
}

@property (nonatomic, copy) NSString *appFolder;

@property (nonatomic, assign) BOOL pauseOnEnterBackground;
@property (nonatomic, assign, getter = isPaused) BOOL isPaused; // Pauses drawing/updating of the JSView
@property (nonatomic, assign) BOOL hasScreenCanvas;

@property (nonatomic, readonly) JSGlobalContextRef jsGlobalContext;
@property (nonatomic, readonly) EJSharedOpenGLContext *openGLContext;

@property (nonatomic, retain) NSObject<EJWindowEventsDelegate> *windowEventsDelegate;
@property (nonatomic, retain) NSObject<EJTouchDelegate> *touchDelegate;
@property (nonatomic, retain) NSObject<EJDeviceMotionDelegate> *deviceMotionDelegate;

@property (nonatomic, retain) EJCanvasContext *currentRenderingContext;
@property (nonatomic, retain) EJCanvasContext<EJPresentable> *screenRenderingContext;

@property (nonatomic, retain) NSOperationQueue *backgroundQueue;
@property (nonatomic, retain) EJClassLoader *classLoader;

- (id)initWithFrame:(CGRect)frame appFolder:(NSString *)folder;

- (void)loadScriptAtPath:(NSString *)path;
- (JSValueRef)evaluateScript:(NSString *)script;
- (JSValueRef)evaluateScript:(NSString *)script sourceURL:(NSString *)sourceURL;
- (void)logException:(JSValueRef)exception ctx:(JSContextRef)ctx;
- (JSValueRef)jsValueForPath:(NSString *)objectPath;

- (void)clearCaches;

- (JSValueRef)invokeCallback:(JSObjectRef)callback thisObject:(JSObjectRef)thisObject argc:(size_t)argc argv:(const JSValueRef [])argv;
- (NSString *)pathForResource:(NSString *)resourcePath;
- (JSValueRef)deleteTimer:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv;
- (JSValueRef)loadModuleWithId:(NSString *)moduleId module:(JSValueRef)module exports:(JSValueRef)exports;
- (JSValueRef)createTimer:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv repeat:(BOOL)repeat;
- (JSValueRef)requestAnimationFrame:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv;
- (JSValueRef)cancelAnimationFrame:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv;
- (JSObjectRef)createFunctionWithBlock:(JSValueRef (^)(JSContextRef ctx, size_t argc, const JSValueRef argv[]))block;

@end
