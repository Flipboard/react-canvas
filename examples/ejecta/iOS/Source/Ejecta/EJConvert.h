#import <Foundation/Foundation.h>
#import "JavaScriptCore/JavaScriptCore.h"


#ifdef __cplusplus
extern "C" {
#endif

NSString *JSValueToNSString( JSContextRef ctx, JSValueRef v );
JSValueRef NSStringToJSValue( JSContextRef ctx, NSString *string );
double JSValueToNumberFast( JSContextRef ctx, JSValueRef v );
void JSValueUnprotectSafe( JSContextRef ctx, JSValueRef v );
JSValueRef NSObjectToJSValue( JSContextRef ctx, NSObject *obj );
NSObject *JSValueToNSObject( JSContextRef ctx, JSValueRef value );

static inline void *JSValueGetPrivate(JSValueRef v) {
	// On 64bit systems we can not safely call JSObjectGetPrivate with any
	// JSValueRef. Doing so with immediate values (numbers, null, bool,
	// undefined) will crash the app. So we check for these first.

	#if __LP64__
		#define JSValueTagMask (0xffff000000000000ll | 0x2ll)
		return !((int64_t)v & JSValueTagMask) ? JSObjectGetPrivate((JSObjectRef)v) : NULL;
	#else
		return JSObjectGetPrivate((JSObjectRef)v);
	#endif
}

#ifdef __cplusplus
}
#endif