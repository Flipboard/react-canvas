#import "EJBindingHttpRequest.h"
#import <JavaScriptCore/JSTypedArray.h>
#import "EJJavaScriptView.h"

@implementation EJBindingHttpRequest

- (id)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctxp argc:argc argv:argv] ) {
		requestHeaders = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)prepareGarbageCollection {
	[self clearRequest];
	[self clearConnection];
}

- (void) dealloc {
	[requestHeaders release];
	[self clearRequest];
	[self clearConnection];
	
	[super dealloc];
}

- (void)clearConnection {
	[connection cancel];
	[connection release]; connection = NULL;
	[responseBody release]; responseBody = NULL;
	[response release]; response = NULL;
}

- (void)clearRequest {
	[method release]; method = NULL;
	[url release]; url = NULL;
	[user release]; user = NULL;
	[password release]; password = NULL;
}

- (NSInteger)getStatusCode {
	if( !response ) {
		return 0;
	}
	else if( [response isKindOfClass:[NSHTTPURLResponse class]] ) {
		return ((NSHTTPURLResponse *)response).statusCode;;
	}
	else {
		return 200; // assume everything went well for non-HTTP resources
	}
}

- (NSString *)getResponseText {
	if( !response || !responseBody ) { return NULL; }
	
	NSStringEncoding encoding = NSASCIIStringEncoding;
	if ( response.textEncodingName ) {
		CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) response.textEncodingName);
		if( cfEncoding != kCFStringEncodingInvalidId ) {
			encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
		}
	}

	return [[[NSString alloc] initWithData:responseBody encoding:encoding] autorelease];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if( user && password && [challenge previousFailureCount] == 0 ) {
		NSURLCredential *credentials = [NSURLCredential
			credentialWithUser:user
			password:password
			persistence:NSURLCredentialPersistenceNone];
		[[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];
	}
	else if( [challenge previousFailureCount] == 0 ) {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
	else {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		state = kEJHttpRequestStateDone;
		[self triggerEvent:@"abort"];
		NSLog(@"XHR: Aborting Request %@ - wrong credentials", url);
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connectionp {
	state = kEJHttpRequestStateDone;
	
	[connection release]; connection = NULL;
	[self triggerEvent:@"load"];
	[self triggerEvent:@"loadend"];
	[self triggerEvent:@"readystatechange"];
	JSValueUnprotectSafe(scriptView.jsGlobalContext, jsObject);
}

- (void)connection:(NSURLConnection *)connectionp didFailWithError:(NSError *)error {
	state = kEJHttpRequestStateDone;
	
	[connection release]; connection = NULL;
	if( error.code == kCFURLErrorTimedOut ) {
		[self triggerEvent:@"timeout"];
	}
	else {
		[self triggerEvent:@"error"];
	}
	[self triggerEvent:@"loadend"];
	[self triggerEvent:@"readystatechange"];
	JSValueUnprotectSafe(scriptView.jsGlobalContext, jsObject);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)responsep {
	state = kEJHttpRequestStateHeadersReceived;
	
	[response release];
	response = (NSHTTPURLResponse *)[responsep retain];
	
	JSContextRef ctx = scriptView.jsGlobalContext;
	[self triggerEvent:@"progress" properties:(JSEventProperty[]){
		{"lengthComputable", JSValueMakeBoolean(ctx, response.expectedContentLength != NSURLResponseUnknownLength)},
		{"total", JSValueMakeNumber(ctx, response.expectedContentLength)},
		{"loaded", JSValueMakeNumber(ctx, responseBody.length)},
		{NULL, NULL}
	}];
	[self triggerEvent:@"readystatechange"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	state = kEJHttpRequestStateLoading;
	
	if( !responseBody ) {
		responseBody = [[NSMutableData alloc] initWithCapacity:1024 * 10]; // 10kb
	}
	[responseBody appendData:data];
	
	JSContextRef ctx = scriptView.jsGlobalContext;
	[self triggerEvent:@"progress" properties:(JSEventProperty[]){
		{"lengthComputable", JSValueMakeBoolean(ctx, response.expectedContentLength != NSURLResponseUnknownLength)},
		{"total", JSValueMakeNumber(ctx, response.expectedContentLength)},
		{"loaded", JSValueMakeNumber(ctx, responseBody.length)},
		{NULL, NULL}
	}];
	[self triggerEvent:@"readystatechange"];
}



EJ_BIND_FUNCTION(open, ctx, argc, argv) {	
	if( argc < 2 ) { return NULL; }
	
	// Cleanup previous request, if any
	[self clearConnection];
	[self clearRequest];
	
	method = [JSValueToNSString( ctx, argv[0] ) retain];
	url = [JSValueToNSString( ctx, argv[1] ) retain];
	async = argc > 2 ? JSValueToBoolean( ctx, argv[2] ) : true;
	
	if( argc > 4 ) {
		user = [JSValueToNSString( ctx, argv[3] ) retain];
		password = [JSValueToNSString( ctx, argv[4] ) retain];
	}
	
	state = kEJHttpRequestStateOpened;
	return NULL;
}

EJ_BIND_FUNCTION(setRequestHeader, ctx, argc, argv) {
	if( argc < 2 ) { return NULL; }
	
	NSString *header = JSValueToNSString( ctx, argv[0] );
	NSString *value = JSValueToNSString( ctx, argv[1] );
	
	requestHeaders[header] = value;
	return NULL;
}

EJ_BIND_FUNCTION(abort, ctx, argc, argv) {
	if( connection ) {
		[self clearConnection];
		[self triggerEvent:@"abort"];
	}
	return NULL;
}

EJ_BIND_FUNCTION(getAllResponseHeaders, ctx, argc, argv) {
	if( !response || ![response isKindOfClass:[NSHTTPURLResponse class]] ) {
		return NULL;
	}
	
	NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
	NSMutableString *headers = [NSMutableString string];
	for( NSString *key in urlResponse.allHeaderFields ) {
		[headers appendFormat:@"%@: %@\n", key, urlResponse.allHeaderFields[key]];
	}
	
	return NSStringToJSValue(ctx, headers);
}

EJ_BIND_FUNCTION(getResponseHeader, ctx, argc, argv) {
	if( argc < 1 || !response || ![response isKindOfClass:[NSHTTPURLResponse class]] ) {
		return NULL;
	}
	
	NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
	NSString *header = JSValueToNSString( ctx, argv[0] );
	NSString *value = urlResponse.allHeaderFields[header];
	
	return value ? NSStringToJSValue(ctx, value) : NULL;
}

EJ_BIND_FUNCTION(overrideMimeType, ctx, argc, argv) {
	// TODO?
	return NULL;
}

EJ_BIND_FUNCTION(send, ctx, argc, argv) {
	if( !method || !url ) { return NULL; }
	
	[self clearConnection];

	NSURL *requestUrl = [NSURL URLWithString:url];
	if( !requestUrl.host ) {
		// No host? Assume we have a local file
		requestUrl = [NSURL fileURLWithPath:[scriptView pathForResource:requestUrl.path]];
	}
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestUrl];
	[request setHTTPMethod:method];
	
	for( NSString *header in requestHeaders ) {
		[request setValue:requestHeaders[header] forHTTPHeaderField:header];
	}
	
	if( argc > 0 ) {
		NSString *requestBody = JSValueToNSString( ctx, argv[0] );
		NSData *requestData = [NSData dataWithBytes:[requestBody UTF8String] length:[requestBody length]];
		[request setHTTPBody:requestData];
	}
	
	if( timeout ) {
		NSTimeInterval timeoutSeconds = (float)timeout/1000.0f;
		[request setTimeoutInterval:timeoutSeconds];
	}	
	
	NSLog(@"XHR: %@ %@", method, url);
	[self triggerEvent:@"loadstart"];
	
	if( async ) {
		state = kEJHttpRequestStateLoading;
		connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	}
	else {	
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
		responseBody = [[NSMutableData alloc] initWithData:data];
		[response retain];
		
		state = kEJHttpRequestStateDone;
		if( [response isKindOfClass:[NSHTTPURLResponse class]] ) {
			NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
			if( urlResponse.statusCode == 200 ) {
				[self triggerEvent:@"load"];
			}
		}
		else {
			[self triggerEvent:@"load"];
		}
		[self triggerEvent:@"loadend"];
		[self triggerEvent:@"readystatechange"];
	}
	[request release];
	
	// Protect this request object from garbage collection, as its callback functions
	// may be the only thing holding on to it
	JSValueProtect(scriptView.jsGlobalContext, jsObject);
	
	return NULL;
}

EJ_BIND_GET(readyState, ctx) {
	return JSValueMakeNumber( ctx, state );
}

EJ_BIND_GET(response, ctx) {
	if( !response || !responseBody ) { return JSValueMakeNull(ctx); }
	
	if( type == kEJHttpRequestTypeArrayBuffer ) {
		JSObjectRef array = JSTypedArrayMake(ctx, kJSTypedArrayTypeArrayBuffer, responseBody.length);
		memcpy(JSTypedArrayGetDataPtr(ctx, array, NULL), responseBody.bytes, responseBody.length);
		return array;
	}
	
	
	NSString *responseText = [self getResponseText];
	if( !responseText ) { return NULL; }
	
	if( type == kEJHttpRequestTypeJSON ) {
		JSStringRef jsText = JSStringCreateWithCFString((CFStringRef)responseText);
		JSObjectRef jsonObject = (JSObjectRef)JSValueMakeFromJSONString(ctx, jsText);
		JSStringRelease(jsText);
		return jsonObject;
	}
	else {
		return NSStringToJSValue( ctx, responseText );
	}
}

EJ_BIND_GET(responseText, ctx) {
	NSString *responseText = [self getResponseText];	
	return responseText ? NSStringToJSValue( ctx, responseText ) : JSValueMakeNull(ctx);
}

EJ_BIND_GET(status, ctx) {
	return JSValueMakeNumber( ctx, [self getStatusCode] );
}

EJ_BIND_GET(statusText, ctx) {
	// FIXME: should be "200 OK" instead of just "200"
	NSString *code = [NSString stringWithFormat:@"%ld", (long)[self getStatusCode]];	
	return NSStringToJSValue(ctx, code);
}

EJ_BIND_GET(timeout, ctx) {
	return JSValueMakeNumber( ctx, timeout );
}

EJ_BIND_SET(timeout, ctx, value) {
	timeout = JSValueToNumberFast( ctx, value );
}

EJ_BIND_ENUM(responseType, type,
	"",				// kEJHttpRequestTypeString
	"arraybuffer",	// kEJHttpRequestTypeArrayBuffer
	"blob",			// kEJHttpRequestTypeBlob
	"document",		// kEJHttpRequestTypeDocument
	"json",			// kEJHttpRequestTypeJSON
	"text"			// kEJHttpRequestTypeText
);

EJ_BIND_CONST(UNSENT, kEJHttpRequestStateUnsent);
EJ_BIND_CONST(OPENED, kEJHttpRequestStateOpened);
EJ_BIND_CONST(HEADERS_RECEIVED, kEJHttpRequestStateHeadersReceived);
EJ_BIND_CONST(LOADING, kEJHttpRequestStateLoading);
EJ_BIND_CONST(DONE, kEJHttpRequestStateDone);

EJ_BIND_EVENT(readystatechange);
EJ_BIND_EVENT(loadend);
EJ_BIND_EVENT(load);
EJ_BIND_EVENT(error);
EJ_BIND_EVENT(abort);
EJ_BIND_EVENT(progress);
EJ_BIND_EVENT(loadstart);
EJ_BIND_EVENT(timeout);

@end
