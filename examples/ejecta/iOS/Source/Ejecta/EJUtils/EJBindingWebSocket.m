#import "EJBindingWebSocket.h"
#import <JavaScriptCore/JSTypedArray.h>

@implementation EJBindingWebSocket

- (id)initWithContext:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv {
	if (self = [super initWithContext:ctx argc:argc argv:argv]) {
		if( argc > 0 ) {
			url = [JSValueToNSString(ctx, argv[0]) retain];
			
			NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
			socket = [[SRWebSocket alloc] initWithURLRequest:request];
			socket.delegate = self;
			[socket open];
			readyState = kEJWebSocketReadyStateConnecting;
		}
		else {
			url = [@"" retain];
			readyState = kEJWebSocketReadyStateClosed;
		}
		
		// FIXME: we don't support the 'blob' type yet, but the spec dictates this should
		// be the default
		binaryType = kEJWebSocketBinaryTypeBlob;
	}
	return self;
}

- (void)createWithJSObject:(JSObjectRef)obj scriptView:(EJJavaScriptView *)view {
	[super createWithJSObject:obj scriptView:view];
	
	if( readyState != kEJWebSocketReadyStateClosed ) {
		// Protect self from garbage collection; the event handlers may be the only
		// thing holding on to us.
		JSValueProtect(view.jsGlobalContext, obj);
	}
}


- (void)prepareGarbageCollection {
	[socket close];
	[socket release];
	socket = nil;
}

- (void) dealloc {
	[url release];
	[socket release];
	[super dealloc];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
	readyState = kEJWebSocketReadyStateOpen;
	
	[self triggerEvent:@"open"];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	readyState = kEJWebSocketReadyStateClosed;
	
	NSLog(@"WebSocket Error: %@", error.description);
	[self triggerEvent:@"error"];
	
	[socket release];
	socket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	JSValueRef jsMessage = NULL;
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	// String?
	if( [message isKindOfClass:[NSString class]] ){
		jsMessage = NSStringToJSValue(ctx, message);
	}
	
	// TypedArray
	else if( [message isKindOfClass:[NSData class]] ) {
		NSData *data = (NSData *)message;
		
		if( binaryType == kEJWebSocketBinaryTypeArrayBuffer ) {
			jsMessage = JSTypedArrayMake(ctx, kJSTypedArrayTypeArrayBuffer, data.length);
			memcpy(JSTypedArrayGetDataPtr(ctx, jsMessage, NULL), data.bytes, data.length);
		}
		else if( binaryType == kEJWebSocketBinaryTypeBlob ) {
			NSLog(@"WebSocket Error: binaryType='blob' is not supported. Use 'arraybuffer' instead.");
			return;
		}
	}
	
	[self triggerEvent:@"message" properties:(JSEventProperty[]){
		{"data", jsMessage},
		{NULL, NULL}
	}];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	readyState = kEJWebSocketReadyStateClosed;
	
	JSContextRef ctx = scriptView.jsGlobalContext;
	[self triggerEvent:@"close" properties:(JSEventProperty[]){
		{"code", JSValueMakeNumber(ctx, code)},
		{"reason", NSStringToJSValue(ctx, reason)},
		{"wasClean", JSValueMakeBoolean(ctx, wasClean)},
		{NULL, NULL},
	}];
	
	
	// Unprotect self from garbage collection
	JSValueUnprotectSafe(scriptView.jsGlobalContext, jsObject);
	
	[socket release];
	socket = nil;
}

EJ_BIND_GET(url, ctx) {
	return NSStringToJSValue(ctx, url);
}

EJ_BIND_GET(readyState, ctx) {
	return JSValueMakeNumber(ctx, readyState);
}

EJ_BIND_GET(bufferedAmount, ctx) {
	// FIXME: SocketRocket doesn't expose this
	return JSValueMakeNumber(ctx, 0);
}

EJ_BIND_GET(extensions, ctx) {
	return NSStringToJSValue(ctx, @"");
}

EJ_BIND_GET(protocol, ctx) {
	return NSStringToJSValue(ctx, @"");
}

EJ_BIND_ENUM(binaryType, binaryType,
	"blob",			// kEJWebSocketBinaryTypeBlob,
	"arraybuffer"	// kEJWebSocketBinaryTypeArrayBuffer
);

EJ_BIND_FUNCTION(send, ctx, argc, argv) {
	if( argc < 1 || readyState != kEJWebSocketReadyStateOpen ) { return NULL; }
	
	// Send string?
	if( JSValueIsString(ctx, argv[0]) ) {
		[socket send:JSValueToNSString(ctx, argv[0])];
	}
	
	// Try TypedArray
	else {
		size_t byteLength;
		void *dataPtr = JSTypedArrayGetDataPtr(ctx, argv[0], &byteLength);
		if( dataPtr && byteLength ) {
			[socket send:[NSData dataWithBytes:dataPtr length:byteLength]];
		}
		else {
			NSLog(@"WebSocket Error: Can't send message that is neither String, ArrayBuffer or ArrayBufferView.");
		}
	}
	
	return NULL;
}

EJ_BIND_FUNCTION(close, ctx, argc, argv) {
	if( readyState == kEJWebSocketReadyStateClosing || readyState == kEJWebSocketReadyStateClosed ) {
		return NULL;
	}
	
	readyState = kEJWebSocketReadyStateClosing;
	[socket close];
	return NULL;
}

EJ_BIND_EVENT(message);
EJ_BIND_EVENT(open);
EJ_BIND_EVENT(error);
EJ_BIND_EVENT(close);

EJ_BIND_CONST(CONNECTING, kEJWebSocketReadyStateConnecting);
EJ_BIND_CONST(OPEN, kEJWebSocketReadyStateOpen);
EJ_BIND_CONST(CLOSING, kEJWebSocketReadyStateClosing);
EJ_BIND_CONST(CLOSED, kEJWebSocketReadyStateClosed);

@end
