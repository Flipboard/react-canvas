#import "EJBindingEventedBase.h"
#import "SRWebSocket.h"

typedef enum {
	kEJWebSocketBinaryTypeBlob,
	kEJWebSocketBinaryTypeArrayBuffer
} EJWebSocketBinaryType;

typedef enum {
	kEJWebSocketReadyStateConnecting = 0,
	kEJWebSocketReadyStateOpen = 1,
	kEJWebSocketReadyStateClosing = 2,
	kEJWebSocketReadyStateClosed = 3
} EJWebSocketReadyState;

@interface EJBindingWebSocket : EJBindingEventedBase <SRWebSocketDelegate> {
	EJWebSocketBinaryType binaryType;
	EJWebSocketReadyState readyState;
	NSString *url;
	SRWebSocket *socket;
}

@end
