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
#import "LoginController.h"
#import "streamingTestAppDelegate.h"

@implementation Controller

@synthesize client, stateDescription;
@synthesize pushTopicsDataSource;

- (id)init {
    self = [super init];
    [self stateChangedTo:sacDisconnected];
    events = [[NSMutableArray alloc] initWithCapacity:32];
    return self;
}

- (void)dealloc {
    [events release];
    [super dealloc];
}

-(void)query:(NSString *)soql doneBlock:(void (^)(NSDictionary *qr))done {
    NSString *path = [NSString stringWithFormat:@"/services/data/v21.0/query?q=%@", [soql stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *qurl = [NSURL URLWithString:path relativeToURL:[[NSApp delegate] instanceUrl]];
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:qurl];
    [r addValue:[NSString stringWithFormat:@"OAuth %@", [[NSApp delegate] sessionId]] forHTTPHeaderField:@"Authorization"];
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
        self.pushTopicsDataSource = [[[PushTopicsDataSource alloc] initWithRows:[qr objectForKey:@"records"] delegate:self] autorelease];
        [topicsTable setDataSource:self.pushTopicsDataSource];
    }];
}

-(void)authenticated:(NSString *)sid onInstance:(NSURL *)instanceUrl {
    [[NSApp delegate] setSessionId:sid];
    [[NSApp delegate] setInstanceUrl:instanceUrl];
    self.client = [[[StreamingApiClient alloc] initWithSessionId:sid instance:instanceUrl] autorelease];
    self.client.delegate = self;
    [self startPushTopicQuery];
}

-(IBAction)clearEvents:(id)sender {
    [events removeAllObjects];
    [eventTable reloadData];
}

-(void)eventOnChannel:(NSString *)eventChannel message:(NSDictionary *)eventMessage {
    [events insertObject:eventMessage atIndex:0];
    [eventTable reloadData];
}

-(void)subscribeTo:(NSString *)subscription {
    [self.client subscribe:subscription];
}

-(void)unsubscribeFrom:(NSString *)subscription {
    [self.client unsubscribe:subscription];
}

-(void)stateChangedTo:(StreamingApiState)newState {
    switch (newState) {
        case sacDisconnected: self.stateDescription = @"Disconnected"; break;
        case sacConnecting:   self.stateDescription = @"Connecting"; break;
        case sacConnected:    self.stateDescription = @"Connected"; break;
        case sacDisconnecting:self.stateDescription = @"Disconnecting"; break;
    }
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
