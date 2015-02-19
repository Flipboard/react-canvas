#import "EJBindingBase.h"
#import "EJFont.h"

@interface EJBindingTextMetrics : EJBindingBase {
	EJTextMetrics metrics;
}

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx scriptView:(EJJavaScriptView *)scriptView metrics:(EJTextMetrics)metrics;

@end
