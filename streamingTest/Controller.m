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

static NSString *OAUTH_CLIENT_ID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF_2HjgFbWgjolmyZp4c1MQ7_J7af1XXPjvW2HXv74c83GbUKEdIcn8S3M7KI";
static NSString *OAUTH_CLIENT_SECRET = @"7341320423187854498";

@implementation Controller

@synthesize username, password, channel, sessionId, instance, client, connected;

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
        self.sessionId = [o objectForKey:@"access_token"];
        self.instance  = [o objectForKey:@"instance_url"];
        self.client = [[[StreamingApiClient alloc] initWithSessionId:self.sessionId instance:[NSURL URLWithString:self.instance]] autorelease];
        self.client.delegate = self;

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
    NSLog(@"%@ %@", eventChannel, eventMessage);
    [events insertObject:eventMessage atIndex:0];
    [eventTable reloadData];
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
