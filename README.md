STOMP client for Objective-C
============================
[![Pod Version](http://img.shields.io/cocoapods/v/YCStompClient.svg?style=flat)](http://cocoadocs.org/docsets/YCStompClient/)
[![Pod Platform](http://img.shields.io/cocoapods/p/YCStompClient.svg?style=flat)](http://cocoadocs.org/docsets/YCStompClient/)
[![Pod License](http://img.shields.io/cocoapods/l/YCStompClient.svg?style=flat)](https://github.com/yuppiu/YCStompClient/blob/master/LICENSE)
[![Dependency Status](https://www.versioneye.com/objective-c/YCStompClient/1.0/badge.svg?style=flat)](https://www.versioneye.com/objective-c/YCStompClient)
[![Reference Status](https://www.versioneye.com/objective-c/YCStompClient/reference_badge.svg?style=flat)](https://www.versioneye.com/objective-c/YCStompClient/references)

This is a simple STOMP client based on [https://github.com/juretta/objc-stomp]
that supports Stomp v1.1 and v1.2. 

Usage
------------

This library was created to work with SocketRocket [https://github.com/square/SocketRocket].
But shoud work with others WebSocket Libraries.

YCStompClient.{h,m} to your project.

MyExample.h

	#import <Foundation/Foundation.h>
	
	@class YCStompClient;
	@protocol YCStompClientDelegate;


	@interface MyExample : NSObject<YCStompClientDelegate> {
    	@private
		YCStompClient *service;
	}
	@property(nonatomic, retain) YCStompClient *service;

	@end


In MyExample.m

	#define kUsername	@"USERNAME"
	#define kPassword	@"PASS"
	#define kQueueName	@"/topic/systemMessagesTopic"

	[...]

	-(void) aMethod {
		YCStompClient *s = [[YCStompClient alloc] 
				initWithHost:@"localhost" 
						port:61613 
						login:kUsername
					passcode:kQueueName
					delegate:self];
		[s connect];
	

		NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: 	
				@"client", @"ack", 
				@"true", @"activemq.dispatchAsync",
				@"1", @"activemq.prefetchSize", nil];
		[s subscribeToDestination:kQueueName withHeader: headers];
	
		[self setService: s];
		[s release];
	}
	
	#pragma mark YCStompClientDelegate
	- (void)stompClientDidConnect:(YCStompClient *)stompService {
			NSLog(@"stompServiceDidConnect");
	}

	- (void)stompClient:(YCStompClient *)stompService messageReceived:(NSString *)body withHeader:(NSDictionary *)messageHeader {
		NSLog(@"gotMessage body: %@, header: %@", body, messageHeader);
		NSLog(@"Message ID: %@", [messageHeader valueForKey:@"message-id"]);
		// If we have successfully received the message ackknowledge it.
		[stompService ack: [messageHeader valueForKey:@"message-id"]];
	}
	
	- (void)dealloc {
		[service unsubscribeFromDestination: kQueueName];
		[service release];
		[super dealloc];
	}
	

Support
------------	
	
Runs fine in iOS5+ and supports ARC.
	
Contributors
------------

This version:
* [Fabio Knoedt](https://github.com/fabioknoedt)

Original code:
* Scott Raymond
* Stefan Saasen
* Graham Haworth
* jbg
