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

#import "StreamingApiClient.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"

@interface StreamingApiClient ()
@property (assign) StreamingApiState currentState;
@property (retain) NSString *clientId;
@end

@implementation StreamingApiClient

@synthesize clientId, delegate;

-(id)initWithSessionId:(NSString *)sid instance:(NSURL *)salesforceInstance {
    self = [super init];
    if (self) {
        cometdUrl = [[NSURL URLWithString:@"/cometd/25.0" relativeToURL:salesforceInstance] retain];
        parser = [[SBJsonParser alloc] init];
        writer = [[SBJsonWriter alloc] init];
        state = sacDisconnected;
        sessionId = [sid retain];
    }
    return self;
}

- (void)dealloc {
    [clientId release];
    [cometdUrl release];
    [parser release];
    [writer release];
    [sessionId release];
    [super dealloc];
}

// builds a POST/CometD request and starts it.
-(void)postCometd:(NSObject *)data delegate:(UrlConnectionDelegate *)requestDelegate {
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:cometdUrl];
    [r setHTTPMethod:@"POST"];
    NSString *json = [writer stringWithObject:data];
    NSLog(@"sending : %@", json);
    [r setHTTPShouldHandleCookies:YES];
    [r addValue:[NSString stringWithFormat:@"Bearer %@", sessionId] forHTTPHeaderField:@"Authorization"];
    [r setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    [r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [[[NSURLConnection alloc] initWithRequest:r delegate:requestDelegate startImmediately:YES] autorelease];
}

// Once we're connected we need to long-poll, get a response, then start a new long-poll
// this is that loop. In additon, if subscription is not nil, we'll also send a subscribe
// request with the connect, this allows us to connect and subscribe in one go, which 
// is more efficent. (TODO, this could allow for multiple subscriptions)
-(void)connectLoopWithSubscribe:(NSString *)subscription {
    NSDictionary *connectMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                @"/meta/connect", @"channel",
                                @"long-polling", @"connectionType", nil];
    
    NSDictionary *subscribeMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                  @"/meta/subscribe", @"channel",
                                  subscription, @"subscription", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *msgs = [parser objectWithData:body];
        if (msgs == nil) 
            NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        NSLog(@"connect returned %@", msgs);
        // the response once we get it can contain mutliple messages, so we need to process each one
        // /meta/connect response is used to start the next long poll
        // other messages not on the /meta/ channels are sent to the delegate.
        __block BOOL didReconnect = NO;
        [msgs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *m = (NSDictionary *)obj;
            NSString *chan = [m objectForKey:@"channel"];
            if (![chan hasPrefix:@"/meta/"]) {
                [self.delegate eventOnChannel:chan message:[m objectForKey:@"data"]];
            } else if ([chan isEqualToString:@"/meta/connect"] && [[m objectForKey:@"successful"] intValue] == 1) {
                self.currentState = sacConnected;
                didReconnect = YES;
                [self connectLoopWithSubscribe:nil];
            }
        }];
        if (!didReconnect) self.currentState = sacDisconnected;
        
    } runOnMainThread:YES];
    NSArray *msgs = subscription == nil ? [NSArray arrayWithObject:connectMsg] : [NSArray arrayWithObjects:connectMsg, subscribeMsg, nil];
    [self postCometd:msgs delegate:d];
}

-(void)startConnect:(NSString *)subscription {
    // we make a handshake request, and once we get the response, we start the connect long-poll loop above.
    self.currentState = sacConnecting;
    NSDictionary *hs = [NSDictionary dictionaryWithObjectsAndKeys:@"/meta/handshake", @"channel", 
                        @"1.0", @"version", 
                        @"1.0", @"minimumVersion", 
                        [NSArray arrayWithObject:@"long-polling"], @"supportedConnectionTypes", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        NSLog(@"handshake returned %lu, %@", httpStatusCode, o);
        self.clientId = [[o objectAtIndex:0] objectForKey:@"clientId"];
        [self connectLoopWithSubscribe:subscription];
        
    } runOnMainThread:YES];
    [self postCometd:[NSArray arrayWithObject:hs] delegate:d];
}

-(void)subscribe:(NSString *)subscription {
    // If we're not connected, then connect & subscribe in one go.
    if (state == sacDisconnected) {
        [self startConnect:subscription];
        return;
    }
    
    // otherwise send a stand-alone subsribe message.
    NSDictionary *subscribeMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                  @"/meta/subscribe", @"channel",
                                  subscription, @"subscription", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        if (o == nil) 
            NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        NSLog(@"subscribe returned %@", o);
        // TODO, handle errors & subscribe responses to delegate
        
    } runOnMainThread:YES];
    [self postCometd:subscribeMsg delegate:d];
}

-(void)unsubscribe:(NSString *)subscription {
    // send an unsubscribe message.
    
    NSDictionary *msg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                  @"/meta/unsubscribe", @"channel",
                                  subscription, @"subscription", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        if (o == nil) 
            NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        NSLog(@"unsubscribe returned %@", o);
        
    } runOnMainThread:YES];
    [self postCometd:msg delegate:d];
}

-(void)stop {
    self.currentState = sacDisconnecting;
    // send a disconnect message, this will cause the server to send a response to close the long-poll request.
    NSDictionary *disconnectMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                  @"/meta/disconnect", @"channel", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        if (o == nil) 
            NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        NSLog(@"disconnect returned %@", o);
        self.currentState = sacDisconnected;
        
    } runOnMainThread:YES];
    [self postCometd:disconnectMsg delegate:d];
}

-(StreamingApiState)currentState {
    return state;
}

-(void)setCurrentState:(StreamingApiState)newState {
    if (newState == state) return;
    state = newState;
    if ([self.delegate respondsToSelector:@selector(stateChangedTo:)])
        [self.delegate stateChangedTo:newState];
}

@end
