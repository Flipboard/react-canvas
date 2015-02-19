#import "EJBindingEventedBase.h"
#import "EJJavaScriptView.h"

@implementation EJBindingEventedBase

- (id)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctxp argc:argc argv:argv] ) {
		eventListeners = [[NSMutableDictionary alloc] init];
		onCallbacks = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	// Unprotect all event callbacks
	for( NSString *type	in eventListeners ) {
		NSArray *listeners = eventListeners[type];
		for( NSValue *callbackValue in listeners ) {
			JSValueUnprotectSafe(ctx, callbackValue.pointerValue);
		}
	}
	[eventListeners release];
	
	// Unprotect all event callbacks
	for( NSString *type in onCallbacks ) {
		NSValue *callbackValue = onCallbacks[type];
		JSValueUnprotectSafe(ctx, callbackValue.pointerValue);
	}
	[onCallbacks release];
	
	[super dealloc];
}

- (JSObjectRef)getCallbackWithType:(NSString *)type ctx:(JSContextRef)ctx {
	NSValue *listener = onCallbacks[type];
	return listener ? [listener pointerValue] : NULL;
}

- (void)setCallbackWithType:(NSString *)type ctx:(JSContextRef)ctx callback:(JSValueRef)callbackValue {
	// remove old event listener?
	JSObjectRef oldCallback = [self getCallbackWithType:type ctx:ctx];
	if( oldCallback ) {
		JSValueUnprotectSafe(ctx, oldCallback);
		[onCallbacks removeObjectForKey:type];
	}
	
	JSObjectRef callback = JSValueToObject(ctx, callbackValue, NULL);
	if( callback && JSObjectIsFunction(ctx, callback) ) {
		JSValueProtect(ctx, callback);
		onCallbacks[type] = [NSValue valueWithPointer:callback];
		return;
	}
}

EJ_BIND_FUNCTION(addEventListener, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	NSString *type = JSValueToNSString( ctx, argv[0] );
	JSObjectRef callback = JSValueToObject(ctx, argv[1], NULL);
	JSValueProtect(ctx, callback);
	NSValue *callbackValue = [NSValue valueWithPointer:callback];
	
	NSMutableArray *listeners = NULL;
	if( (listeners = eventListeners[type]) ) {
		[listeners addObject:callbackValue];
	}
	else {
		eventListeners[type] = [NSMutableArray arrayWithObject:callbackValue];
	}
	return NULL;
}

EJ_BIND_FUNCTION(removeEventListener, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	NSString *type = JSValueToNSString( ctx, argv[0] );

	NSMutableArray *listeners = NULL;
	if( (listeners = eventListeners[type]) ) {
		JSObjectRef callback = JSValueToObject(ctx, argv[1], NULL);
		for( int i = 0; i < listeners.count; i++ ) {
			if( JSValueIsStrictEqual(ctx, callback, [listeners[i] pointerValue]) ) {
				JSValueUnprotect(ctx, [listeners[i] pointerValue]);
				[listeners removeObjectAtIndex:i];
				return NULL;
			}
		}
	}
	return NULL;
}

- (void)triggerEvent:(NSString *)type argc:(int)argc argv:(JSValueRef[])argv {
	NSArray *listeners = eventListeners[type];
	if( listeners ) {
		for( NSValue *callback in listeners ) {
			[scriptView invokeCallback:callback.pointerValue thisObject:jsObject argc:argc argv:argv];
		}
	}
	
	NSValue *callback = onCallbacks[type];
	if( callback ) {
		[scriptView invokeCallback:callback.pointerValue thisObject:jsObject argc:argc argv:argv];
	}
}

- (void)triggerEvent:(NSString *)type {
	[self triggerEvent:type properties:nil];
}

- (void)triggerEvent:(NSString *)type properties:(JSEventProperty[])properties {
	NSArray *listeners = eventListeners[type];
	NSValue *onCallback = onCallbacks[type];
	
	// Check if we have any listeners before constructing the event object
	if( !(listeners && listeners.count) && !onCallback ) {
		return;
	}
	
	// Build the event object
	JSObjectRef jsEvent = [EJBindingEvent createJSObjectWithContext:scriptView.jsGlobalContext
		scriptView:scriptView type:type target:jsObject];
	
	// Attach all additional properties, if any
	if( properties ) {
		for( int i = 0; properties[i].name; i++ ) {
			JSStringRef name = JSStringCreateWithUTF8CString(properties[i].name);
			JSValueRef value = properties[i].value;
			JSObjectSetProperty(scriptView.jsGlobalContext, jsEvent, name, value, kJSPropertyAttributeReadOnly, NULL);
			JSStringRelease(name);
		}
	}
	
	
	JSValueRef params[] = { jsEvent };
	if( listeners ) {
		for( NSValue *callback in listeners ) {
			[scriptView invokeCallback:callback.pointerValue thisObject:jsObject argc:1 argv:params];
		}
	}
	
	if( onCallback ) {
		[scriptView invokeCallback:onCallback.pointerValue thisObject:jsObject argc:1 argv:params];
	}
}

@end


@implementation EJBindingEvent

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)scriptView
	type:(NSString *)type
	target:(JSObjectRef)target
{
	EJBindingEvent *event = [[self alloc] initWithContext:ctx argc:0 argv:NULL];
	JSValueProtect(ctx, target);
	event->jsTarget = target;
	event->type = [type retain];
	
	JSObjectRef jsEvent = [self createJSObjectWithContext:ctx scriptView:scriptView instance:event];
	[event release];
	return jsEvent;
}

- (void)dealloc {
	[type release];
	JSValueUnprotectSafe(scriptView.jsGlobalContext, jsTarget);
	
	[super dealloc];
}

EJ_BIND_GET(target, ctx) { return jsTarget; }
EJ_BIND_GET(currentTarget, ctx) { return jsTarget; }
EJ_BIND_GET(type, ctx) { return NSStringToJSValue(ctx, type); }

EJ_BIND_FUNCTION(preventDefault, ctx, argc, argv){ return NULL; }
EJ_BIND_FUNCTION(stopPropagation, ctx, argc, argv){ return NULL; }

@end
