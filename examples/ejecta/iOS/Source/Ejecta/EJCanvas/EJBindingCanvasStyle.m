#import "EJBindingCanvasStyle.h"

#import "EJBindingCanvas.h"

@implementation EJBindingCanvasStyle
@synthesize binding;

- (JSObjectRef)jsObject {
	return jsObject;
}

#define EJ_BIND_PX_STYLE(NAME, TARGET) \
	EJ_BIND_GET(NAME, ctx) { \
		return NSStringToJSValue(ctx, [NSString stringWithFormat:@"%fpx", TARGET]);\
	} \
	\
	EJ_BIND_SET(NAME, ctx, value) { \
		if( JSValueIsNumber(ctx, value) ) { \
			TARGET = JSValueToNumberFast(ctx, value); \
			return; \
		} \
		NSString *valueString = JSValueToNSString(ctx, value); \
		if( valueString.length > 0 ) { \
			float NAME; \
			sscanf( valueString.UTF8String, "%fpx", &NAME); \
			TARGET = NAME; \
		} \
		else { \
			TARGET = 0; \
		} \
	}

	EJ_BIND_PX_STYLE(width, binding.styleWidth);
	EJ_BIND_PX_STYLE(height, binding.styleHeight);
	EJ_BIND_PX_STYLE(left, binding.styleLeft);
	EJ_BIND_PX_STYLE(top, binding.styleTop);

#undef EJ_BIND_PX_STYLE

@end
