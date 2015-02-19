#import "EJBindingCanvasPattern.h"

@implementation EJBindingCanvasPattern

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	pattern:(EJCanvasPattern *)pattern
{
	EJBindingCanvasPattern *binding = [[EJBindingCanvasPattern alloc] initWithContext:ctx argc:0 argv:NULL];
	binding->pattern = [pattern retain];
	
	JSObjectRef obj = [self createJSObjectWithContext:ctx scriptView:view instance:binding];
	[binding release];
	return obj;
}

+ (EJCanvasPattern *)patternFromJSValue:(JSValueRef)value {
	if( !value ) { return NULL; }
	
	EJBindingCanvasPattern *binding = (EJBindingCanvasPattern *)JSValueGetPrivate(value);
	return (binding && [binding isKindOfClass:[EJBindingCanvasPattern class]]) ? binding->pattern : NULL;
}

- (void)dealloc {
	[pattern release];
	[super dealloc];
}

@end
