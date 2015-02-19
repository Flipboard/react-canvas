#import "EJBindingLocalStorage.h"


@implementation EJBindingLocalStorage

EJ_BIND_FUNCTION(getItem, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	NSString *key = JSValueToNSString( ctx, argv[0] );
	NSString *value = [NSUserDefaults.standardUserDefaults stringForKey:key];
	return value ? NSStringToJSValue( ctx, value ) : JSValueMakeNull(ctx);
}

EJ_BIND_FUNCTION(setItem, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	NSString *key = JSValueToNSString( ctx, argv[0] );
	NSString *value = JSValueToNSString( ctx, argv[1] );
	
	if( !key || !value ) { return NULL; }
	[NSUserDefaults.standardUserDefaults setObject:value forKey:key];
	[NSUserDefaults.standardUserDefaults synchronize];
	
	return NULL;
}

EJ_BIND_FUNCTION(removeItem, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	NSString *key = JSValueToNSString( ctx, argv[0] );
	[NSUserDefaults.standardUserDefaults removeObjectForKey:key];
	
	return NULL;
}

EJ_BIND_FUNCTION(clear, ctx, argc, argv) {
	[NSUserDefaults.standardUserDefaults removePersistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
	return NULL;
}

EJ_BIND_FUNCTION(key, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	int index = JSValueToNumberFast(ctx, argv[0]);
	
	// TODO: cache this maybe?
	NSDictionary *keys = [NSUserDefaults.standardUserDefaults persistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
	NSString *key = keys.allKeys[index];
	return key ? NSStringToJSValue(ctx, key) : NULL;
}

EJ_BIND_GET(length, ctx) {
	// TODO: cache this maybe?
	NSDictionary *keys = [NSUserDefaults.standardUserDefaults persistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
	return JSValueMakeNumber(ctx, keys.count);
}


@end
