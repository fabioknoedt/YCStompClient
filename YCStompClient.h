//
//  YCStompClient.h
//  Objc-Stomp
//
//
//  Implements the Stomp Protocol v1.1
//  See: http://stomp.github.io/stomp-specification-1.1.html
// 
//  Requires the Socket Rocket library
//  See: https://github.com/square/SocketRocket
//  
//  See: LICENSE
//  Based on StompService.{h,m} by Scott Raymond <sco@scottraymond.net>.
//  Modified by Fabio Knoedt adapting the version above to work with RocketSocket framework and Stomp 1.2.

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

@class YCStompClient;

typedef enum {
	YCStompAckModeAuto,
	YCStompAckModeClient
} YCStompAckMode;

@protocol YCStompClientDelegate <NSObject>
- (void)stompClient:(YCStompClient *)stompService messageReceived:(NSString *)body withHeader:(NSDictionary *)messageHeader;

@optional
- (void)stompClientDidDisconnect:(YCStompClient *)stompService;
- (void)stompClientWillDisconnect:(YCStompClient *)stompService withError:(NSError*)error;
- (void)stompClientDidConnect:(YCStompClient *)stompService;
- (void)serverDidSendReceipt:(YCStompClient *)stompService withReceiptId:(NSString *)receiptId;
- (void)serverDidSendError:(YCStompClient *)stompService withErrorMessage:(NSString *)description detailedErrorMessage:(NSString *) theMessage;
- (void)serverDidSendPing;
@end

@interface YCStompClient : NSObject {
	@private
	SRWebSocket *_webSocket;
	NSString *host;
	NSUInteger port;
	NSString *login;
	NSString *passcode;
	NSString *sessionId;
	BOOL doAutoconnect;
	BOOL anonymous;
    BOOL wss;
}

@property (nonatomic, assign) id<YCStompClientDelegate> delegate;

- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
			 login:(NSString *)theLogin
		  passcode:(NSString *)thePasscode 
		  delegate:(id<YCStompClientDelegate>)theDelegate;

- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
			 login:(NSString *)theLogin
		  passcode:(NSString *)thePasscode 
		  delegate:(id<YCStompClientDelegate>)theDelegate
	   autoconnect:(BOOL)autoconnect
               wss:(BOOL)wss;

/**
 * Connects as an anonymous user. Suppresses "login" and "passcode" headers.
 */
- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
		  delegate:(id<YCStompClientDelegate>)theDelegate
	   autoconnect:(BOOL) autoconnect;

- (void)connect;
- (void)connect:(NSString *)newHost withPort:(NSUInteger)newPort;
- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination;
- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination withReceipt:(NSString *)receipt;
- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination withHeaders:(NSDictionary*)headers;
- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination withHeaders:(NSDictionary*)headers withReceipt:(NSString *)receipt;
- (void)subscribeToDestination:(NSString *)destination;
- (void)subscribeToDestination:(NSString *)destination withAck:(YCStompAckMode) ackMode;
- (void)subscribeToDestination:(NSString *)destination withHeader:(NSDictionary *) header;
- (void)unsubscribeFromDestination:(NSString *)destination;
- (void)begin:(NSString *)transactionId;
- (void)commit:(NSString *)transactionId;
- (void)abort:(NSString *)transactionId;
- (void)ack:(NSString *)messageId;
- (void)ack:(NSString *)messageId withSubscription:(NSString *)subscription;
- (void)disconnect;

@end
