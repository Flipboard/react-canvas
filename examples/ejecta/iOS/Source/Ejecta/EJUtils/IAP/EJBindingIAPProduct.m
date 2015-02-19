#import "EJBindingIAPProduct.h"
#import "EJBindingIAPTransaction.h"

@implementation EJBindingIAPProduct

- (id)initWithProduct:(SKProduct *)productp {
	if( self = [super initWithContext:NULL argc:0 argv:NULL] ) {
		product = [productp retain];
	}
	return self;
}

- (void)dealloc {
	[product release];
	[super dealloc];
}

- (void)finishPurchaseWithTransaction:(SKPaymentTransaction *)transaction {
	if( !callback ) {
		NSLog(@"IAP Error: Payment finished but no callback. This shouldn't happen.");
		return;
	}
	
	JSGlobalContextRef ctx = scriptView.jsGlobalContext;
	
	// Construct the error value and transaction binding for the callback
	JSValueRef jsError = (transaction.transactionState == SKPaymentTransactionStateFailed)
		? NSStringToJSValue(ctx, transaction.error.localizedDescription)
		: JSValueMakeNull(ctx);
	
	JSValueRef jsTransaction = [EJBindingIAPTransaction
		createJSObjectWithContext:ctx scriptView:scriptView transaction:transaction];
	
	[scriptView invokeCallback:callback thisObject:jsObject
		argc:2 argv:(JSValueRef[]){jsError, jsTransaction}];
	
	
	JSValueUnprotect(scriptView.jsGlobalContext, callback);
	JSValueUnprotect(scriptView.jsGlobalContext, jsObject);
	callback = NULL;
}

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(EJJavaScriptView *)view
	product:(SKProduct *)product
{
	id native = [[self alloc] initWithProduct:product];
	
	JSObjectRef obj = [self createJSObjectWithContext:ctx scriptView:view instance:native];
	[native release];
	return obj;
}

+ (EJBindingIAPProduct *)bindingFromJSValue:(JSValueRef)value {
	if( !value ) { return 0; }
	
	EJBindingIAPProduct *binding = (EJBindingIAPProduct *)JSValueGetPrivate(value);
	return (binding && [binding isKindOfClass:[self class]]) ? binding : NULL;
}

EJ_BIND_GET(id, ctx) {
	return NSStringToJSValue(ctx, product.productIdentifier);
}

EJ_BIND_GET(title, ctx) {
	return NSStringToJSValue(ctx, product.localizedTitle);
}

EJ_BIND_GET(description, ctx) {
	return NSStringToJSValue(ctx, product.localizedDescription);
}

EJ_BIND_GET(price, ctx) {
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:product.priceLocale];
	NSString *localizedPrice = [numberFormatter stringFromNumber:product.price];
	[numberFormatter release];
		
	return NSStringToJSValue(ctx, localizedPrice);
}

EJ_BIND_FUNCTION(purchase, ctx, argc, argv) {
	if( argc < 2 || !JSValueIsObject(ctx, argv[1]) ) { return NULL; }
	
	if( callback ) {
		NSLog(
			@"IAP Error: Can't make purchase for %@ while another purchase for the "
			@"same product is still running",
			product.productIdentifier
		);
		return NULL;
	}
	
	int quantity = JSValueToNumberFast(ctx, argv[0]);
	
	NSLog(@"IAP: Purchase %@ x %d", product.productIdentifier, quantity);
	
	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
	payment.quantity = quantity;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
	
	callback = JSValueToObject(ctx, argv[1], NULL);
	JSValueProtect(ctx, callback);
	JSValueProtect(ctx, jsObject);
	return NULL;
}

@end
