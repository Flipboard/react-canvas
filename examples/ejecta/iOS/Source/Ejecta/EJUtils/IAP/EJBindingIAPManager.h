#import "EJBindingBase.h"
#import <StoreKit/StoreKit.h>

@interface EJBindingIAPManager : EJBindingBase <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
	NSMutableDictionary *productRequestCallbacks;
	NSMutableDictionary *products;
	
	JSObjectRef restoreCallback;
	NSMutableArray *restoredTransactions;
}
@end
