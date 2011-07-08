//
//  StreamingApiClient.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>

@protocol StreamingApiClientDelegate <NSObject>

@required
-(void)eventOnChannel:(NSString *)channel message:(NSDictionary *)eventMessage;

@optional
-(void)connected:(NSString *)clientId;
-(void)disconnected;

@end

@class SBJsonParser, SBJsonWriter;

@interface StreamingApiClient : NSObject {
    NSObject<StreamingApiClientDelegate> *delegate;

    BOOL            connected;
    NSString        *clientId;
    NSURL           *cometdUrl;
    
    SBJsonParser    *parser;
    SBJsonWriter    *writer;
}

-(id)initWithSessionId:(NSString *)sessionId instance:(NSURL *)salesforceInstance;

@property (assign) NSObject<StreamingApiClientDelegate> *delegate;

-(BOOL)connected;
-(NSString *)clientId;

-(void)startConnect:(NSString *)subscription;
-(void)subscribe:(NSString *)subscription;
-(void)stop;

@end
