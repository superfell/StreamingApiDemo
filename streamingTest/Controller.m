//
//  Controller.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"

static NSString *OAUTH_CLIENT_ID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF_2HjgFbWgjolmyZp4c1MQ7_J7af1XXPjvW2HXv74c83GbUKEdIcn8S3M7KI";
static NSString *OAUTH_CLIENT_SECRET = @"7341320423187854498";

@implementation Controller

@synthesize username, password, channel, sessionId, instance;

- (id)init {
    self = [super init];
    self.username = @"sforce2@zaks.demon.co.uk";
    self.channel = @"/Accounts";
    return self;
}

- (void)dealloc {
    [super dealloc];
}

-(void)login:(id)sender {
    NSString *params = [NSString stringWithFormat:@"grant_type=password&client_id=%@&client_secret=%@&username=%@&password=%@",
                            [OAUTH_CLIENT_ID stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                            [OAUTH_CLIENT_SECRET stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                            [self.username stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                            [self.password stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:@"https://login.salesforce.com/services/oauth2/token"];
    
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:url];
    [r setHTTPMethod:@"POST"];
    [r setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    UrlConnectionDelegateWithBlock *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        NSDictionary *o = [p objectWithData:body];
        self.sessionId = [o objectForKey:@"access_token"];
        self.instance  = [o objectForKey:@"instance_url"];
        
    } runOnMainThread:YES];
    
    [[[NSURLConnection alloc] initWithRequest:r delegate:d startImmediately:YES] autorelease];
}

-(void)postCometd:(NSObject *)data delegate:(UrlConnectionDelegate *)delegate {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/cometd", self.instance]];
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:url];
    [r setHTTPMethod:@"POST"];
    SBJsonWriter *w = [[[SBJsonWriter alloc] init] autorelease];
    NSString *json = [w stringWithObject:data];
    NSLog(@"json : %@", json);
    [r setHTTPShouldHandleCookies:YES];
    [r setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
//    [r addValue:[NSString stringWithFormat:@"sid=%@", self.sessionId] forHTTPHeaderField:@"Cookie"];
    [r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[[NSURLConnection alloc] initWithRequest:r delegate:delegate startImmediately:YES] autorelease];
}

-(void)subscribe:(NSString *)clientId {
    NSDictionary *subscribe = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                               @"/meta/subscribe", @"channel",
                               self.channel, @"subscription", nil];
    
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        NSObject *o = [p objectWithData:body];
        NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        NSLog(@"subscribe returned %@", o);
        
    } runOnMainThread:YES];
    [self postCometd:[NSArray arrayWithObject:subscribe] delegate:d];
}

-(void)connectLoop:(NSString *)clientId doSubscribe:(BOOL)subscribe {
    NSDictionary *connect = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                             @"/meta/connect", @"channel",
                             @"long-polling", @"connectionType", nil];

    NSDictionary *subscribeMsg = [NSDictionary dictionaryWithObjectsAndKeys:clientId, @"clientId",
                               @"/meta/subscribe", @"channel",
                               self.channel, @"subscriptionX", nil];

    Controller *me = self;
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        NSObject *o = [p objectWithData:body];
        NSLog(@"raw data : %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        NSLog(@"connect returned %@", o);
        
//        if (subscribe) [me subscribe:clientId];
        
        if (httpStatusCode == 200)
            [me connectLoop:clientId doSubscribe:NO];
        
    } runOnMainThread:YES];
    NSArray *msgs = subscribe ? [NSArray arrayWithObjects:connect, subscribeMsg, nil] : [NSArray arrayWithObject:connect];
    [self postCometd:msgs delegate:d];
}

-(void)start:(id)sender {
    NSDictionary *hs = [NSDictionary dictionaryWithObjectsAndKeys:@"/meta/handshake", @"channel", 
                        @"1.0", @"version", 
                        @"1.0", @"minimumVersion", 
                        [NSArray arrayWithObject:@"long-polling"], @"supportedConnectionTypes", nil];
    
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSDictionary *sidProps = [NSDictionary dictionaryWithObjectsAndKeys:self.sessionId, NSHTTPCookieValue,
                              @"sid", NSHTTPCookieName,
//                              @"TRUE", NSHTTPCookieSecure,
                              @"/", NSHTTPCookiePath,
                              @".salesforce.com", NSHTTPCookieDomain,
//                              [NSString stringWithFormat:@"%@/", self.instance], NSHTTPCookieOriginURL,
                              nil];
    NSHTTPCookie *c = [NSHTTPCookie cookieWithProperties:sidProps];
    [cookies setCookie:c];
    
    Controller *me = self;
    UrlConnectionDelegate *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        NSArray *o = [p objectWithData:body];
        NSLog(@"handshake returned %lu, %@", httpStatusCode, o);
        [me connectLoop:[[o objectAtIndex:0] objectForKey:@"clientId"] doSubscribe:YES];
        
    } runOnMainThread:YES];
    [self postCometd:[NSArray arrayWithObject:hs] delegate:d];
}

-(void)stop:(id)sender {
    
}

@end
