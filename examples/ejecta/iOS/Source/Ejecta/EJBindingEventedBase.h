#import "EJBindingBase.h"


// ------------------------------------------------------------------------------------
// Events; shorthand for EJ_BIND_GET/SET - use with EJ_BIND_EVENT( eventname );

#define EJ_BIND_EVENT(NAME) \
	static JSValueRef _get_on##NAME( \
		JSContextRef ctx, \
		JSObjectRef object, \
		JSStringRef propertyName, \
		JSValueRef* exception \
	) { \
		EJBindingEventedBase *instance = (EJBindingEventedBase*)JSObjectGetPrivate(object); \
		return [instance getCallbackWithType:( @ #NAME) ctx:ctx]; \
	} \
	__EJ_GET_POINTER_TO(_get_on##NAME) \
	\
	static bool _set_on##NAME( \
		JSContextRef ctx, \
		JSObjectRef object, \
		JSStringRef propertyName, \
		JSValueRef value, \
		JSValueRef* exception \
	) { \
		EJBindingEventedBase *instance = (EJBindingEventedBase*)JSObjectGetPrivate(object); \
		[instance setCallbackWithType:( @ #NAME) ctx:ctx callback:value]; \
		return true; \
	} \
	__EJ_GET_POINTER_TO(_set_on##NAME)


typedef struct {
	const char *name;
	JSValueRef value;
} JSEventProperty;
	
@interface EJBindingEventedBase : EJBindingBase {
	NSMutableDictionary *eventListeners; // for addEventListener
	NSMutableDictionary *onCallbacks; // for on* setters
}

- (JSObjectRef)getCallbackWithType:(NSString *)type ctx:(JSContextRef)ctx;
- (void)setCallbackWithType:(NSString *)type ctx:(JSContextRef)ctx callback:(JSValueRef)callback;
- (void)triggerEvent:(NSString *)type argc:(int)argc argv:(JSValueRef[])argv;
- (void)triggerEvent:(NSString *)type properties:(JSEventProperty[])properties;
- (void)triggerEvent:(NSString *)type;

@end


@interface EJBindingEvent : EJBindingBase {
	NSString *type;
	JSObjectRef jsTarget;
}

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)scriptView
	type:(NSString *)type
	target:(JSObjectRef)target;
	
@end

