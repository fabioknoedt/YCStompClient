//
//  YCStompClient.h
//  Objc-Stomp
//
//
//  Implements the Stomp Protocol v1.2
//  See: http://stomp.github.io/stomp-specification-1.2.html
//
//  Requires the Socket Rocket library
//  See: https://github.com/square/SocketRocket
//
//  See: LICENSE
//  Based on StompService.{h,m} by Scott Raymond <sco@scottraymond.net>.
//  Modified by Fabio Knoedt adapting the version above to work with RocketSocket framework and Stomp 1.2.

#import "YCStompClient.h"

#define kStompDefaultPort			61613
#define kDefaultTimeout				5	//


#define kCommandConnect				@"CONNECT"
#define kCommandSend				@"SEND"
#define kCommandSubscribe			@"SUBSCRIBE"
#define kCommandUnsubscribe			@"UNSUBSCRIBE"
#define kCommandBegin				@"BEGIN"
#define kCommandCommit				@"COMMIT"
#define kCommandAbort				@"ABORT"
#define kCommandAck					@"ACK"
#define kCommandDisconnect			@"DISCONNECT"
#define kCommandPing                @"\n"
#define	kControlChar				[NSString stringWithFormat:@"\n%C", (unsigned short)0x00]

#define kCommandHeaderReceipt       @"receipt"
#define kCommandHeaderDestination   @"destination"
#define kCommandHeaderDestinationId @"id"
#define kCommandHeaderContentType   @"content-type"
#define kCommandHeaderContentLength @"content-length"
#define kCommandHeaderAck           @"ack"
#define kCommandHeaderTransaction   @"transaction"
#define kCommandHeaderMessageId     @"message-id"
#define kCommandHeaderSubscription  @"subscription"
#define kCommandHeaderDisconnected  @"disconnected"
#define kCommandHeaderLogin         @"login"
#define kCommandHeaderPassword      @"password"
#define kCommandHeaderHeartBeat     @"heart-beat"
#define kCommandHeaderAcceptVersion @"accept-version"

#define kAckClient					@"client"
#define kAckAuto					@"auto"

#define kResponseHeaderSession		@"session"
#define kResponseHeaderReceiptId	@"receipt-id"
#define kResponseHeaderErrorMessage @"message"

#define kResponseFrameConnected		@"CONNECTED"
#define kResponseFrameMessage		@"MESSAGE"
#define kResponseFrameReceipt		@"RECEIPT"
#define kResponseFrameError			@"ERROR"

#define kNoSocketConnection         @"There is no websocket connection. Impossible to communicate with Stomp."

#define YC_RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }

@interface YCStompClient() <SRWebSocketDelegate> 

@property (nonatomic, assign) NSUInteger port;
@property (nonatomic, retain) SRWebSocket *_webSocket;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSString *login;
@property (nonatomic, copy) NSString *passcode;
@property (nonatomic, copy) NSString *sessionId;

@end

@interface YCStompClient(PrivateMethods)
- (void) sendFrame:(NSString *) command withHeader:(NSDictionary *) header andBody:(NSString *) body;
- (void) sendFrame:(NSString *) command;
@end

@implementation YCStompClient

@synthesize delegate;
@synthesize _webSocket, host, port, login, passcode, sessionId;

- (id)init {
	return [self initWithHost:@"localhost" port:kStompDefaultPort login:nil passcode:nil delegate:nil];
}

- (id)initWithHost:(NSString *)theHost
			  port:(NSUInteger)thePort 
		  delegate:(id<YCStompClientDelegate>)theDelegate
	   autoconnect:(BOOL) autoconnect
{
	if(self = [self initWithHost:theHost port:thePort login:nil passcode:nil delegate:theDelegate autoconnect:NO wss:NO]) {
		anonymous = YES;
	}
	return self;
}

- (id)initWithHost:(NSString *)theHost
			  port:(NSUInteger)thePort 
			 login:(NSString *)theLogin 
		  passcode:(NSString *)thePasscode 
		  delegate:(id<YCStompClientDelegate>)theDelegate
{
	return [self initWithHost:theHost port:thePort login:theLogin passcode:thePasscode delegate:theDelegate autoconnect:NO wss:NO];
}

- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
			 login:(NSString *)theLogin 
		  passcode:(NSString *)thePasscode 
		  delegate:(id<YCStompClientDelegate>)theDelegate
	   autoconnect:(BOOL) autoconnect
               wss:(BOOL)wssconnection
{
    
	if(self = [super init]) {

		anonymous = NO;
		doAutoconnect = autoconnect;
        wss = wssconnection;
        
		[self setDelegate:theDelegate];
		[self setHost: theHost];
		[self setPort: thePort];
		[self setLogin: theLogin];
		[self setPasscode: thePasscode];
        
        // Call to open the socket. The socket will be assign to the object only after the socket is opened.
        [self openSocket];
	}
	return self;
}

#pragma mark -
#pragma mark Public methods
- (void)openSocket
{
    if ((_webSocket == NULL) || _webSocket.readyState == SR_CLOSED) {
        
        NSString *prefix = wss ? @"wss" :  @"ws";
        NSString *url = [NSString stringWithFormat: @"%@://%@:%lu", prefix, self.host, (unsigned long)self.port];
        NSLog(@"URL %@", url);
        
        _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        _webSocket.delegate = self;
        
        NSLog(@"Opening a new socket...");
        [_webSocket open];
    }
}


- (void)connect:(NSString *)newHost withPort:(NSUInteger)newPort {
    
    self.host = newHost;
    self.port = newPort;
    
    [self connect];
}

- (void)connect {

    if(_webSocket.readyState == SR_OPEN) {
    
        NSLog(@">>> Connecting to Stomp...");
        
        if(anonymous) {
            [self sendFrame:kCommandConnect];
        } else {
            // Setting up the usarname, password AND the heart-beat to 10 seconds. TO-DO: variable change.
            NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: [self login], kCommandHeaderLogin, [self passcode], kCommandHeaderPassword, @"1.1", kCommandHeaderAcceptVersion, @"10000,10000", kCommandHeaderHeartBeat, nil];
            [self sendFrame:kCommandConnect withHeader:headers andBody: nil];
        }
        
    } else {
        
        [self openSocket];
    }
}

- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination {
    [self sendMessage:theMessage toDestination:destination withHeaders:[NSDictionary dictionary] withReceipt:nil];
}

- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination withHeaders:(NSDictionary*)headers {
    [self sendMessage:theMessage toDestination:destination withHeaders:headers withReceipt:nil];
}

- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination withReceipt:(NSString *)receipt {
    [self sendMessage:theMessage toDestination:destination withHeaders:[NSDictionary dictionary] withReceipt:receipt];
}

- (void)sendMessage:(id)theMessage toDestination:(NSString *)destination withHeaders:(NSDictionary*)headers withReceipt:(NSString *)receipt {

    NSMutableDictionary *allHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    
    // Setting up the receipt.
    if ([receipt length]) {
        [allHeaders setValue:receipt forKey:kCommandHeaderReceipt];
    }
    
    // Setting up the destination: destination is a MUST have.
    if ([destination length] && theMessage) {
        
        [allHeaders setValue:destination forKey:kCommandHeaderDestination];
        
        // Setting up content type.
        if ([theMessage isKindOfClass:[NSString class]]) {
            
            // Setting up the content length.
            [allHeaders setValue:[NSString stringWithFormat:@"%li", (unsigned long)[theMessage length]] forKey:kCommandHeaderContentLength];
            // Setting up content type as plain text.
            [allHeaders setValue:@"text/plain" forKey:kCommandHeaderContentType];
            
        } else {
            
            NSLog(@"Stomp message content type is not a string!");
        }
        
        [self sendFrame:kCommandSend withHeader:allHeaders andBody:theMessage];
    
    } else {

        NSLog(@"Error: No destination or message! A MESSAGE frame must have a destination.");
    }
}

- (void)subscribeToDestination:(NSString *)destination {
	[self subscribeToDestination:destination withAck:YCStompAckModeAuto];
}

- (void)subscribeToDestination:(NSString *)destination withAck:(YCStompAckMode) ackMode {
	NSString *ack;
	switch (ackMode) {
		case YCStompAckModeClient:
			ack = kAckClient;
			break;
		default:
			ack = kAckAuto;
			break;
	}
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: destination, kCommandHeaderDestination, ack, kCommandHeaderAck, destination, kCommandHeaderDestinationId, nil];
    [self sendFrame:kCommandSubscribe withHeader:headers andBody:nil];
}

- (void)subscribeToDestination:(NSString *)destination withHeader:(NSDictionary *) header {
	NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithDictionary:header];
	[headers setObject:destination forKey:kCommandHeaderDestination];
    [self sendFrame:kCommandSubscribe withHeader:headers andBody:nil];
}

- (void)unsubscribeFromDestination:(NSString *)destination {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: destination, kCommandHeaderDestinationId, nil];
    [self sendFrame:kCommandUnsubscribe withHeader:headers andBody:nil];
}

-(void)begin:(NSString *)transactionId {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: transactionId, kCommandHeaderTransaction, nil];
    [self sendFrame:kCommandBegin withHeader:headers andBody:nil];
}

- (void)commit:(NSString *)transactionId {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: transactionId, kCommandHeaderTransaction, nil];
    [self sendFrame:kCommandCommit withHeader:headers andBody:nil];
}

- (void)abort:(NSString *)transactionId {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: transactionId, kCommandHeaderTransaction, nil];
    [self sendFrame:kCommandAbort withHeader:headers andBody:nil];
}

- (void)ack:(NSString *)messageId {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: messageId, kCommandHeaderMessageId, nil];
    [self sendFrame:kCommandAck withHeader:headers andBody:nil];
}

- (void)ack:(NSString *)messageId withSubscription:(NSString *)subscription {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: messageId, kCommandHeaderMessageId, subscription, kCommandHeaderSubscription, nil];
    [self sendFrame:kCommandAck withHeader:headers andBody:nil];
}

- (void)disconnect
{
    NSLog(@"Disconnecting from Stomp...");
    [self sendFrame:kCommandDisconnect withHeader:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%lld", (long long int)[[NSDate date] timeIntervalSince1970]], kCommandHeaderReceipt, nil] andBody:nil];
}


#pragma mark -
#pragma mark PrivateMethods
- (void) sendFrame:(NSString *)command withHeader:(NSDictionary *)header andBody:(id)body {
    
    if(_webSocket.readyState == SR_OPEN) {
    
        NSMutableString *frameString = [NSMutableString stringWithString:@""];
        
        if (command) {
            frameString = [NSMutableString stringWithString: [command stringByAppendingString:@"\n"]];
        }
        for (id key in header) {
            [frameString appendString:key];
            [frameString appendString:@":"];
            [frameString appendString:[header objectForKey:key]];
            [frameString appendString:@"\n"];
        }
        if (body) {

            if ([body isKindOfClass:[NSString class]]) {

                [frameString appendString:@"\n"];
                [frameString appendString:body];

            } else if ([body isKindOfClass:[NSData class]]) {

                NSLog(@"The message content is not a string.");
            }
        }
        
        // Change here to support binary data.
        [frameString appendString:kControlChar];
        
        // Double check because sometimes the connection looses.
        if(_webSocket.readyState == SR_OPEN) {
            NSLog(@">>> Sending frame: %@\n%@\n%@", command, header, body);
            [_webSocket send:frameString];
        }
        
    } else {
        
        NSLog(kNoSocketConnection);
        if([[self delegate] respondsToSelector:@selector(stompClientDidDisconnect:)]) {
            [[self delegate] stompClientDidDisconnect:self];
        }
    }
}

- (void)sendFrame:(NSString *)command
{    
    [self sendFrame:command withHeader:nil andBody:nil];
}

- (void)receiveFrame:(NSString *)command headers:(NSDictionary *)headers body:(NSString *)body
{
    //NSLog(@"receiveCommand '%@' [%@], %@", command, headers, body);
	
	// Connected
	if([kResponseFrameConnected isEqual:command]) {
		if([[self delegate] respondsToSelector:@selector(stompClientDidConnect:)]) {
			[[self delegate] stompClientDidConnect:self];
		}
		
		// store session-id
		NSString *sessId = [headers valueForKey:kResponseHeaderSession];
		[self setSessionId: sessId];
	
	// Response 
	} else if([kResponseFrameMessage isEqual:command]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // Load information from database in background to avoid freezing.
                [[self delegate] stompClient:self messageReceived:body withHeader:headers];
            });
        });
		//[[self delegate] stompClient:self messageReceived:body withHeader:headers];
		
	// Receipt
	} else if([kResponseFrameReceipt isEqual:command]) {		
		if([[self delegate] respondsToSelector:@selector(serverDidSendReceipt:withReceiptId:)]) {
			NSString *receiptId = [headers valueForKey:kResponseHeaderReceiptId];
			[[self delegate] serverDidSendReceipt:self withReceiptId: receiptId];
		}
    
    // Pong from the server
    } else if([command length]==0) {
        
        NSLog(@"<<< PONG");
        [_webSocket send:kCommandPing];
        NSLog(@">>> PING");
        
        if([[self delegate] respondsToSelector:@selector(serverDidSendPing)]) {
            [[self delegate] serverDidSendPing];
        }

        /*if (_webSocket.readyState == SR_OPEN) {
        
            NSLog(@"<<< PONG");
            [_webSocket send:kCommandPing];
            if([[self delegate] respondsToSelector:@selector(serverDidSendPing)]) {
                [[self delegate] serverDidSendPing];
            }
            NSLog(@">>> PING");
        
        } else {

            NSLog(kNoSocketConnection);
            if([[self delegate] respondsToSelector:@selector(stompClientDidDisconnect:)]) {
                [[self delegate] stompClientDidDisconnect: self];
            }
        }*/
        
	// Error
	} else if([kResponseFrameError isEqual:command]) {
		if([[self delegate] respondsToSelector:@selector(serverDidSendError:withErrorMessage:detailedErrorMessage:)]) {
			NSString *msg = [headers valueForKey:kResponseHeaderErrorMessage];
			[[self delegate] serverDidSendError:self withErrorMessage: msg detailedErrorMessage: body];
		}		
	}
}

#pragma mark -
#pragma mark SRWebSocketDelegate

// The WebSocket was sucessfully opened.
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"<<< Websocket connected");
    
    [self set_webSocket:webSocket];
    
    if(doAutoconnect) {
        [self connect];
    }
}

// The WebSocket received some message from the server.
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSData *strData = [message subdataWithRange:NSMakeRange(0, [message length])];
	NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
    NSMutableArray *contents = (NSMutableArray *)[[msg componentsSeparatedByString:@"\n"] mutableCopy];
	if([[contents objectAtIndex:0] isEqual:@""]) {
		[contents removeObjectAtIndex:0];
	}
	NSString *command = [[contents objectAtIndex:0] copy];
	NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
	NSMutableString *body = [[NSMutableString alloc] init];
	BOOL hasHeaders = NO;
    [contents removeObjectAtIndex:0];
	for(NSString *line in contents) {
		if(hasHeaders) {
			[body appendString:line];
		} else {
			if ([line isEqual:@""]) {
				hasHeaders = YES;
			} else {
				// message-id can look like this: message-id:ID:macbook-pro.local-50389-1237007652070-5:6:-1:1:1
				NSMutableArray *parts = [NSMutableArray arrayWithArray:[line componentsSeparatedByString:@":"]];
				// key ist the first part
				NSString *key = [parts objectAtIndex:0];
				[parts removeObjectAtIndex:0];
				[headers setObject:[parts componentsJoinedByString:@":"] forKey:key];
			}
		}
	}
    
    [self receiveFrame:command headers:headers body:body];
}

// The WebSocket closed the connection. Probably because your timeout.
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"<<< WebSocket closed!");

	if([[self delegate] respondsToSelector:@selector(stompClientDidDisconnect:)]) {
		[[self delegate] stompClientDidDisconnect: self];
	}
}

// The WebSocket failed and returned a error.
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@"<<< Websocket Failed With Error %@", error);
	if([[self delegate] respondsToSelector:@selector(serverDidSendError:withErrorMessage:detailedErrorMessage:)]) {
		[[self delegate] serverDidSendError:self withErrorMessage:error.domain detailedErrorMessage:error.description];
	}
}

#pragma mark -
#pragma mark Memory management
-(void) dealloc {
	delegate = nil;
}

@end
