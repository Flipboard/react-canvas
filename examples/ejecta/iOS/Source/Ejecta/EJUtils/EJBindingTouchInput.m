#import "EJBindingTouchInput.h"

@implementation EJBindingTouchInput

- (void)createWithJSObject:(JSObjectRef)obj scriptView:(EJJavaScriptView *)view {
	[super createWithJSObject:obj scriptView:view];
	
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	// Create the JavaScript arrays that will be passed to the callback
	jsRemainingTouches = JSObjectMakeArray(ctx, 0, NULL, NULL);
	JSValueProtect(ctx, jsRemainingTouches);
	
	jsChangedTouches = JSObjectMakeArray(ctx, 0, NULL, NULL);
	JSValueProtect(ctx, jsChangedTouches);
	
	// Create some JSStrings for property access
	jsLengthName = JSStringCreateWithUTF8CString("length");
	
	jsIdentifierName = JSStringCreateWithUTF8CString("identifier");
	jsPageXName = JSStringCreateWithUTF8CString("pageX");
	jsPageYName = JSStringCreateWithUTF8CString("pageY");
	jsClientXName = JSStringCreateWithUTF8CString("clientX");
	jsClientYName = JSStringCreateWithUTF8CString("clientY");
	
	scriptView.touchDelegate = self;
}

- (void)dealloc {
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	JSValueUnprotectSafe( ctx, jsRemainingTouches );
	JSValueUnprotectSafe( ctx, jsChangedTouches );
	JSStringRelease( jsLengthName );
	
	JSStringRelease( jsIdentifierName );
	JSStringRelease( jsPageXName );
	JSStringRelease( jsPageYName );
	JSStringRelease( jsClientXName );
	JSStringRelease( jsClientYName );
	
	for( int i = 0; i < touchesInPool; i++ ) {
		JSValueUnprotectSafe( ctx, jsTouchesPool[i] );
	}
	
	[super dealloc];
}

- (void)triggerEvent:(NSString *)name all:(NSSet *)all changed:(NSSet *)changed remaining:(NSSet *)remaining {
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	NSUInteger remainingCount = MIN(remaining.count, EJ_TOUCH_INPUT_MAX_TOUCHES);
	NSUInteger changedCount = MIN(changed.count, EJ_TOUCH_INPUT_MAX_TOUCHES);
	NSUInteger totalCount = MAX(remainingCount, changedCount);
	
	JSObjectSetProperty(ctx, jsRemainingTouches, jsLengthName, JSValueMakeNumber(ctx, remainingCount), kJSPropertyAttributeNone, NULL);
	JSObjectSetProperty(ctx, jsChangedTouches, jsLengthName, JSValueMakeNumber(ctx, changedCount), kJSPropertyAttributeNone, NULL);
	
	// More touches than we have in our pool? Create some!
	if( touchesInPool < totalCount ) {
		for( NSUInteger i = touchesInPool; i < totalCount; i++ ) {
			jsTouchesPool[i] = JSObjectMake( ctx, NULL, NULL );
			JSValueProtect( ctx, jsTouchesPool[i] );
		}
		touchesInPool = totalCount;
	}
	
	int
		poolIndex = 0,
		remainingIndex = 0,
		changedIndex = 0;
		
	for( UITouch *touch in all ) {
		CGPoint pos = [touch locationInView:touch.view];
		
		JSValueRef identifier = JSValueMakeNumber(ctx, touch.hash );
		JSValueRef x = JSValueMakeNumber(ctx, pos.x);
		JSValueRef y = JSValueMakeNumber(ctx, pos.y);
		
		JSObjectRef jsTouch = jsTouchesPool[poolIndex++];
		JSObjectSetProperty( ctx, jsTouch, jsIdentifierName, identifier, kJSPropertyAttributeNone, NULL );
		JSObjectSetProperty( ctx, jsTouch, jsPageXName, x, kJSPropertyAttributeNone, NULL );
		JSObjectSetProperty( ctx, jsTouch, jsPageYName, y, kJSPropertyAttributeNone, NULL );
		JSObjectSetProperty( ctx, jsTouch, jsClientXName, x, kJSPropertyAttributeNone, NULL );
		JSObjectSetProperty( ctx, jsTouch, jsClientYName, y, kJSPropertyAttributeNone, NULL );
		
		if( [remaining member:touch] ) {
			JSObjectSetPropertyAtIndex(ctx, jsRemainingTouches, remainingIndex++, jsTouch, NULL);
		}
		
		if( [changed member:touch] ) {
			JSObjectSetPropertyAtIndex(ctx, jsChangedTouches, changedIndex++, jsTouch, NULL);
		}
		
		if( poolIndex >= touchesInPool ) { break; }
	}
	
	[self triggerEvent:name argc:2 argv:(JSValueRef[]){ jsRemainingTouches, jsChangedTouches }];
}

EJ_BIND_EVENT(touchstart);
EJ_BIND_EVENT(touchend);
EJ_BIND_EVENT(touchmove);


@end
