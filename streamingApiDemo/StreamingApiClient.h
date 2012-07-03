// Copyright (c) 2011 Simon Fell
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>

// This class wraps the streaming API, you create an instance with the users
// sessionId & instanceUrl, and then tell it to connect, and which channels
// aka PushTopics to subscribe to. The delegate will get callback to update
// it with info about what's going on, like the connection state, and any
// data messages that are pushed to us from the server.

// the different connection states.
typedef enum {
    sacDisconnected,    
    sacConnecting,      // this includes the cometd handshake & connect steps
    sacConnected,       // long polling connected, you can now receive messages if you've subscribed to something
    sacDisconnecting    // we're in the process of terminating the long polling.
} StreamingApiState;

// You implement the delegate protocol in one of your classes to get updates
// about what's going on, including the events from the server on the 
// channels/topics you subscribed to.
@protocol StreamingApiClientDelegate <NSObject>

@required
-(void)eventOnChannel:(NSString *)channel message:(NSDictionary *)eventMessage;

@optional
-(void)stateChangedTo:(StreamingApiState)newState;

// TODO: need to report errors.
@end

@class SBJsonParser, SBJsonWriter;

// The actual streaming api client, this manages the http connections, the cometd protocol
// and all the json handling, it reports events & state via the delegate.
@interface StreamingApiClient : NSObject {
    NSObject<StreamingApiClientDelegate> *delegate;

    NSString            *sessionId;
    NSString            *clientId;
    NSURL               *cometdUrl;
    StreamingApiState   state;
    
    SBJsonParser        *parser;
    SBJsonWriter        *writer;
}

// The primary initializer, you can get a sessionId & instanceUrl from a soap or oauth login process.
-(id)initWithSessionId:(NSString *)sessionId instance:(NSURL *)salesforceInstance;

// The delegate, this is how you get notified about messages recieved.
@property (assign) NSObject<StreamingApiClientDelegate> *delegate;

// This is the cometD clientId, assigned to us during the handshake step, its nothing to do with the soap APIs clientId.
-(NSString *)clientId;

// the current state of the client.
-(StreamingApiState)currentState;

// start the handshake/connection process and optionally subscribe 
// to a channel during the connection process.
-(void)startConnect:(NSString *)subscription;   

// will start connecting if not already connected, subscription should be /{PushTopicName}
// a single client instance can be subscribed to multiple channels at once.
-(void)subscribe:(NSString *)subscription;

// unsubscribe from a channel you'd previous subscribed to.
-(void)unsubscribe:(NSString *)subscription;

// stop/disconnect the client, this will cleanly unregister the client and complete any outstanding http requests/long polls.
-(void)stop;

@end
