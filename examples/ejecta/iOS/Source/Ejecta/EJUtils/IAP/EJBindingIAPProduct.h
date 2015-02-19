#import "EJBindingBase.h"
#import <StoreKit/StoreKit.h>

@interface EJBindingIAPProduct : EJBindingBase {
	SKProduct *product;
	JSObjectRef callback;
}

- (id)initWithProduct:(SKProduct *)product;
- (void)finishPurchaseWithTransaction:(SKPaymentTransaction *)transaction;

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	product:(SKProduct *)product;

+ (EJBindingIAPProduct *)bindingFromJSValue:(JSValueRef)value;


@end
