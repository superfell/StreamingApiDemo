//
//  StreamingApiClient.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>

typedef enum {
    sacDisconnected,
    sacConnecting,
    sacConnected,
    sacDisconnecting
} StreamingApiState;

@protocol StreamingApiClientDelegate <NSObject>

@required
-(void)eventOnChannel:(NSString *)channel message:(NSDictionary *)eventMessage;

@optional
-(void)stateChangedTo:(StreamingApiState)newState;

@end

@class SBJsonParser, SBJsonWriter;

@interface StreamingApiClient : NSObject {
    NSObject<StreamingApiClientDelegate> *delegate;

    NSString            *clientId;
    NSURL               *cometdUrl;
    StreamingApiState   state;
    
    SBJsonParser        *parser;
    SBJsonWriter        *writer;
}

-(id)initWithSessionId:(NSString *)sessionId instance:(NSURL *)salesforceInstance;

@property (assign) NSObject<StreamingApiClientDelegate> *delegate;

-(NSString *)clientId;
-(StreamingApiState)currentState;

-(void)startConnect:(NSString *)subscription;
-(void)subscribe:(NSString *)subscription;      // will start connecting if not already connected.
-(void)unsubscribe:(NSString *)subscription;
-(void)stop;

@end
