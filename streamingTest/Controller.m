//
//  Controller.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import "Controller.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"
#import "StreamingApiClient.h"
#import "NSObject+SBJson.h"
#import "PushTopicsDataSource.h"
#import "NewPushTopicController.h"
#import "streamingTestAppDelegate.h"

static NSString *OAUTH_CLIENT_ID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF_2HjgFbWgjolmyZp4c1MQ7_J7af1XXPjvW2HXv74c83GbUKEdIcn8S3M7KI";
static NSString *OAUTH_CLIENT_SECRET = @"7341320423187854498";

@implementation Controller

@synthesize username, password, channel, sessionId, instance, client, connected;
@synthesize loggedIn, pushTopicsDataSource;

- (id)init {
    self = [super init];
    self.username = @"sforce2@zaks.demon.co.uk";
    self.channel = @"/Accounts";
    events = [[NSMutableArray alloc] initWithCapacity:32];
    return self;
}

- (void)dealloc {
    [events release];
    [super dealloc];
}

-(void)query:(NSString *)soql doneBlock:(void (^)(NSDictionary *qr))done {
    NSString *path = [NSString stringWithFormat:@"/services/data/v21.0/query?q=%@", [soql stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *qurl = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:self.instance]];
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:qurl];
    [r addValue:[NSString stringWithFormat:@"OAuth %@", self.sessionId] forHTTPHeaderField:@"Authorization"];
    UrlConnectionDelegateWithBlock *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        if (httpStatusCode == 200) {
            NSDictionary *qr = [p objectWithData:body];
            done(qr);
        } 
        // TODO handle errors
    } runOnMainThread:YES];
    [[[NSURLConnection alloc] initWithRequest:r delegate:d startImmediately:YES] autorelease];
}

-(IBAction)addPushTopic:(id)sender {
    NSWindow *myWindow = [[NSApp delegate] window];
    [newTopicController showSheetForWindow:myWindow topicBlock:^(NSDictionary *newTopic) {
        NSLog(@"newTopic is %@", newTopic);
        if (newTopic == nil) return;
        [self.pushTopicsDataSource addObject:newTopic];
        [topicsTable reloadData];
    }];
}

-(void)startPushTopicQuery {
    [self query:@"select name, query, apiVersion from pushTopic order by name" doneBlock:^(NSDictionary *qr) {
        self.pushTopicsDataSource = [[[PushTopicsDataSource alloc] initWithRows:[qr objectForKey:@"records"]] autorelease];
        [topicsTable setDataSource:self.pushTopicsDataSource];
    }];
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
        // TODO check for errors
        NSString *e = [o objectForKey:@"error"];
        if (e == nil) {
            self.sessionId = [o objectForKey:@"access_token"];
            self.instance  = [o objectForKey:@"instance_url"];
            self.client = [[[StreamingApiClient alloc] initWithSessionId:self.sessionId instance:[NSURL URLWithString:self.instance]] autorelease];
            self.client.delegate = self;
            self.loggedIn = YES;
            [[NSApp delegate] setSessionId:self.sessionId];
            [[NSApp delegate] setInstanceUrl:[NSURL URLWithString:self.instance]];
            [self startPushTopicQuery];
        }
    } runOnMainThread:YES];
    
    [[[NSURLConnection alloc] initWithRequest:r delegate:d startImmediately:YES] autorelease];
}

-(void)start:(id)sender {
    [self.client startConnect:self.channel];
}

-(void)stop:(id)sender {
    [self.client stop];
}

-(void)eventOnChannel:(NSString *)eventChannel message:(NSDictionary *)eventMessage {
    [events insertObject:eventMessage atIndex:0];
    [eventTable reloadData];
}

-(IBAction)subscribe:(id)sender {
    NSLog(@"subscribe %@", sender);
}

-(void)connected:(NSString *)clientId {
    self.connected = YES;
}

-(void)disconnected {
    self.connected = NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return events.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *e = [events objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"when"])
        return [e objectForKey:@"eventCreatedDate"];
    return [e JSONRepresentation];
}

@end
