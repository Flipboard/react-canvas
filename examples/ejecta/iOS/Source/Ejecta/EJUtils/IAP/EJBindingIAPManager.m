#import "EJBindingIAPManager.h"
#import "EJBindingIAPProduct.h"
#import "EJBindingIAPTransaction.h"


@implementation EJBindingIAPManager

- (id)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctxp argc:argc argv:argv] ) {
		productRequestCallbacks = [NSMutableDictionary new];
		products = [NSMutableDictionary new];
		restoredTransactions = [NSMutableArray new];
		
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	}
	return self;
}

- (void)prepareGarbageCollection {
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)dealloc {
	for( NSValue *v in productRequestCallbacks.allValues ) {
		JSValueUnprotectSafe(scriptView.jsGlobalContext, v.pointerValue);
	}
	[productRequestCallbacks release];
	
	for( NSValue *v in products.allValues ) {
		JSValueUnprotectSafe(scriptView.jsGlobalContext, v.pointerValue);
	}
	[products release];
	
	[restoredTransactions release];
	JSValueUnprotectSafe(scriptView.jsGlobalContext, restoreCallback);
	
	[super dealloc];
}

- (JSObjectRef)getJSProductWithProduct:(SKProduct *)product {
	// Create a new IAPProduct or return it straight if it was created previously
	if( products[product.productIdentifier] ) {
		return [products[product.productIdentifier] pointerValue];
	}
	
	JSGlobalContextRef ctx = scriptView.jsGlobalContext;
	JSObjectRef jsProduct = [EJBindingIAPProduct
		createJSObjectWithContext:ctx scriptView:scriptView product:product];

	JSValueProtect(ctx, jsProduct);
	products[product.productIdentifier] = [NSValue valueWithPointer:jsProduct];
	
	return jsProduct;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	NSValue *requestKey = [NSValue valueWithPointer:(void *)request];
	NSValue *callback = productRequestCallbacks[requestKey];
	
	if( !callback ) {
		NSLog(@"IAP: Error: product request finished, but no callback set.");
		[request release];
		return;
	}
	
	// Go through all products; construct the bindings and the js array containing them
	JSGlobalContextRef ctx = scriptView.jsGlobalContext;
	JSValueRef *jsArrayArgs = malloc( sizeof(JSValueRef) * response.products.count);
	int count = 0;
	for( SKProduct *product in response.products ) {
		jsArrayArgs[count++] = [self getJSProductWithProduct:product];
	}
	
	JSObjectRef jsCallback = callback.pointerValue;
	JSObjectRef jsArray = JSObjectMakeArray(ctx, count, jsArrayArgs, NULL);
	
	// Construct the error value if some of the products could not be identified
	JSValueRef jsError = (response.invalidProductIdentifiers.count > 0)
		? NSStringToJSValue(ctx, [@"Invalid Product Ids: "
			stringByAppendingString:[response.invalidProductIdentifiers componentsJoinedByString:@", "]])
		: JSValueMakeNull(ctx);
	
	// Invoke the callback and clean up
	[scriptView invokeCallback:jsCallback thisObject:jsObject
		argc:2 argv:(JSValueRef[]){jsError, jsArray}];
	
	JSValueUnprotect(scriptView.jsGlobalContext, jsCallback);
	[productRequestCallbacks removeObjectForKey:requestKey];
	
	[request release];
}


- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for( SKPaymentTransaction *transaction in transactions ) {
		// Restored - safe transaction to send it out once the restore is complete
		if( transaction.transactionState == SKPaymentTransactionStateRestored ) {
			[restoredTransactions addObject:transaction];
			[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		}
		
		// Purchased or failed purchases - notify the product
		else if(
			transaction.transactionState == SKPaymentTransactionStatePurchased ||
			transaction.transactionState == SKPaymentTransactionStateFailed
		) {
			JSObjectRef jsProduct = [products[transaction.payment.productIdentifier] pointerValue];
			EJBindingIAPProduct *binding = [EJBindingIAPProduct bindingFromJSValue:jsProduct];
			[binding finishPurchaseWithTransaction:transaction];
			
			[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		}
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	if( !restoreCallback ) { return; }
	
	JSGlobalContextRef ctx = scriptView.jsGlobalContext;
	
	// Create the error string and an empty transactions array
	JSValueRef jsError = NSStringToJSValue(ctx, error.localizedDescription);
	JSObjectRef jsArray = JSObjectMakeArray(ctx, 0, NULL, NULL);
	
	[scriptView invokeCallback:restoreCallback thisObject:jsObject
		argc:2 argv:(JSValueRef[]){jsError, jsArray}];
	
	// Unset the callback
	JSValueUnprotect(ctx, restoreCallback);
	restoreCallback = NULL;
	[restoredTransactions removeAllObjects];
	
	JSValueUnprotect(ctx, jsObject);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	if( !restoreCallback ) { return; }
	
	JSGlobalContextRef ctx = scriptView.jsGlobalContext;
	
	// Create all IAPTransaction objects
	JSValueRef *jsArrayArgs = malloc( sizeof(JSValueRef) * restoredTransactions.count);
	int count = 0;
	for( SKPaymentTransaction *transaction in restoredTransactions ) {
		jsArrayArgs[count++] = [EJBindingIAPTransaction
			createJSObjectWithContext:ctx scriptView:scriptView transaction:transaction];
	}
	
	// Create the empty error value and the transactions array
	JSValueRef jsError = JSValueMakeNull(ctx);
	JSObjectRef jsArray = JSObjectMakeArray(ctx, count, jsArrayArgs, NULL);
	
	[scriptView invokeCallback:restoreCallback thisObject:jsObject
		argc:2 argv:(JSValueRef[]){jsError, jsArray}];
		
	// Unset the callback
	JSValueUnprotect(ctx, restoreCallback);
	restoreCallback = NULL;
	[restoredTransactions removeAllObjects];
	
	JSValueUnprotect(ctx, jsObject);
}

EJ_BIND_FUNCTION(getProducts, ctx, argc, argv) {
	if( argc < 2 || !JSValueIsObject(ctx, argv[0]) || !JSValueIsObject(ctx, argv[1]) ) {
		return NULL;
	}
	
	NSArray *productIds = (NSArray *)JSValueToNSObject(ctx, argv[0]);
	if( ![productIds isKindOfClass:NSArray.class] ) {
		return NULL;
	}
	NSLog(@"IAP: Requesting product info: %@", [productIds componentsJoinedByString:@", "]);
	
	// Construct the request and insert it together with the callback into the
	// productRequestCallbacks dict
	SKProductsRequest *request = [[SKProductsRequest alloc]
		initWithProductIdentifiers:[NSSet setWithArray:productIds]];
	request.delegate = self;
	
	JSValueProtect(ctx, argv[1]);
	NSValue *callback = [NSValue valueWithPointer:argv[1]];
	NSValue *requestKey = [NSValue valueWithPointer:(void *)request];
	productRequestCallbacks[requestKey] = callback;
	
	[request start];
	return NULL;
}

EJ_BIND_FUNCTION(restoreTransactions, ctx, argc, argv) {
	if( argc < 1 || restoreCallback || !JSValueIsObject(ctx, argv[0]) ) { return NULL; }
	
	NSLog(@"IAP: Restore transactions");
	
	restoreCallback = (JSObjectRef)argv[0];
	JSValueProtect(ctx, restoreCallback);
	JSValueProtect(ctx, jsObject);
	
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	return NULL;
}

@end

