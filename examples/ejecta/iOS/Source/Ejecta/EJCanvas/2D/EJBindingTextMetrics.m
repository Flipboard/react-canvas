#import "EJBindingTextMetrics.h"

@implementation EJBindingTextMetrics

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	metrics:(EJTextMetrics)metrics
{
	EJBindingTextMetrics *binding = [[EJBindingTextMetrics alloc] initWithContext:ctx argc:0 argv:NULL];
	binding->metrics = metrics;
	
	JSObjectRef obj = [self createJSObjectWithContext:ctx scriptView:view instance:binding];
	[binding release];
	return obj;
}

EJ_BIND_GET(width, ctx) {
	return JSValueMakeNumber(ctx, metrics.width);
}

EJ_BIND_GET(actualBoundingBoxAscent, ctx) {
	return JSValueMakeNumber(ctx, metrics.ascent);
}

EJ_BIND_GET(actualBoundingBoxDescent, ctx) {
	return JSValueMakeNumber(ctx, metrics.descent);
}

@end
