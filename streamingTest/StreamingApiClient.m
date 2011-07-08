//
//  StreamingApiClient.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import "StreamingApiClient.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"

@interface StreamingApiClient ()
@property (assign) BOOL connected;
@property (retain) NSString *clientId;
@end

@implementation StreamingApiClient

@synthesize clientId, connected, delegate;

-(id)initWithSessionId:(NSString *)sid instance:(NSURL *)salesforceInstance {
    self = [super init];
    if (self) {
        cometdUrl = [[NSURL URLWithString:@"/cometd" relativeToURL:salesforceInstance] retain];
        parser = [[SBJsonParser alloc] init];
        writer = [[SBJsonWriter alloc] init];
        
        // set the Sid cookie in the cookie store
        NSDictionary *sidCookieProps = [NSDictionary dictionaryWithObjectsAndKeys:sid, NSHTTPCookieValue,
                                  @"sid", NSHTTPCookieName,
                                  @"TRUE", NSHTTPCookieSecure,
                                  @"/", NSHTTPCookiePath,
                                  [salesforceInstance host], NSHTTPCookieDomain,
                                  nil];
        NSHTTPCookie *c = [NSHTTPCookie cookieWithProperties:sidCookieProps];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:c];
    }
    return self;
}

- (void)dealloc {
    [clientId release];
    [cometdUrl release];
    [parser release];
    [writer release];
    [super dealloc];
}

-(void)postCometd:(NSObject *)data delegate:(UrlConnectionDelegate *)requestDelegate {
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:cometdUrl];
    [r setHTTPMethod:@"POST"];
    NSString *json = [writer stringWithObject:data];
    NSLog(@"sending : %@", json);
    [r setHTTPShouldHandleCookies:YES];
    [r setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    [r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[[NSURLConnection alloc] initWithRequest:r delegate:requestDelegate startImmediately:YES] autorelease];
}

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
        [msgs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *m = (NSDictionary *)obj;
            NSString *chan = [m objectForKey:@"channel"];
            if (![chan hasPrefix:@"/meta/"])
                [self.delegate eventOnChannel:chan message:[m objectForKey:@"data"]];
            else if ([chan isEqualToString:@"/meta/connect"] && [[m objectForKey:@"successful"] intValue] == 1)
                [self connectLoopWithSubscribe:nil];
        }];
        
    } runOnMainThread:YES];
    NSArray *msgs = subscription == nil ? [NSArray arrayWithObject:connectMsg] : [NSArray arrayWithObjects:connectMsg, subscribeMsg, nil];
    [self postCometd:msgs delegate:d];
}

-(void)startConnect:(NSString *)subscription {
    // do handshake, then start connect loop
    NSDictionary *hs = [NSDictionary dictionaryWithObjectsAndKeys:@"/meta/handshake", @"channel", 
                        @"1.0", @"version", 
                        @"1.0", @"minimumVersion", 
                        [NSArray arrayWithObject:@"long-polling"], @"supportedConnectionTypes", nil];
    
    StreamingApiClient *me = self;
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        NSLog(@"handshake returned %lu, %@", httpStatusCode, o);
        self.clientId = [[o objectAtIndex:0] objectForKey:@"clientId"];
        self.connected = TRUE;
        if ([self.delegate respondsToSelector:@selector(connected:)])
            [self.delegate connected:self.clientId];
        
        [me connectLoopWithSubscribe:subscription];
        
    } runOnMainThread:YES];
    [self postCometd:[NSArray arrayWithObject:hs] delegate:d];
}

-(void)subscribe:(NSString *)subscription {
    NSDictionary *subscribeMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                  @"/meta/subscribe", @"channel",
                                  subscription, @"subscription", nil];
    
//    StreamingApiClient *me = self;
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        if (o == nil) 
            NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        NSLog(@"connect returned %@", o);
        
        // TODO
//        if (httpStatusCode == 200)
  //          [me connectLoopWithSubscribe:nil];
        
    } runOnMainThread:YES];
    [self postCometd:subscribeMsg delegate:d];
}

-(void)stop {
    NSDictionary *disconnectMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                                  @"/meta/disconnect", @"channel", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        NSArray *o = [parser objectWithData:body];
        if (o == nil) 
            NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        NSLog(@"disconnect returned %@", o);
        if ([self.delegate respondsToSelector:@selector(disconnected)])
            [self.delegate disconnected];
        
    } runOnMainThread:YES];
    [self postCometd:disconnectMsg delegate:d];
}

@end
