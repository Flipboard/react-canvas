#import "EJBindingIAPTransaction.h"

@implementation EJBindingIAPTransaction

- (id)initWithTransaction:(SKPaymentTransaction *)transactionp {
	if( self = [super initWithContext:NULL argc:0 argv:NULL] ) {
		transaction	= [transactionp retain];
	}
	return self;
}

- (void)dealloc {
	[transaction release];
	[super dealloc];
}

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	transaction:(SKPaymentTransaction *)transaction
{
	id native = [[self alloc] initWithTransaction:transaction];
	
	JSObjectRef obj = [self createJSObjectWithContext:ctx scriptView:view instance:native];
	[native release];
	return obj;
}

EJ_BIND_GET(id, ctx) {
	return NSStringToJSValue(ctx, transaction.transactionIdentifier);
}

EJ_BIND_GET(productId, ctx) {
	return NSStringToJSValue(ctx, transaction.payment.productIdentifier);
}

EJ_BIND_GET(receipt, ctx) {
	NSData *receipt = [NSData dataWithContentsOfURL:NSBundle.mainBundle.appStoreReceiptURL];
	if( !receipt ) {
		return NULL;
	}
	return NSStringToJSValue(ctx, [receipt base64EncodedStringWithOptions:0]);
}

@end
