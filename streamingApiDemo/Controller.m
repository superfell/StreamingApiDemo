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

#import "Controller.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"
#import "NSObject+SBJson.h"
#import "StreamingApiClient.h"
#import "PushTopicsDataSource.h"
#import "DetailsDataSource.h"
#import "NewPushTopicController.h"
#import "StreamingApiDemoAppDelegate.h"

@implementation Controller

@synthesize client, stateDescription;
@synthesize pushTopicsDataSource;

- (id)init {
    self = [super init];
    [self stateChangedTo:sacDisconnected];
    events = [[NSMutableArray alloc] initWithCapacity:32];
    // Sat Jul 09 04:57:38 GMT 2011
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss zzz yyyy"];
    return self;
}

- (void)dealloc {
    [events release];
    [dateFormatter release];
    [super dealloc];
}

// Helper method to start a HTTP request against the REST Apis Query URL, when we get the results the doneBlock is called with the parsed QueryResult structure.
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

// This is called when you click the + above the PushTopic table to create a new push topic
// This uses NewPushTopicController to manage the form sheet and make the API calls
// when/if a new topic is created, we'll add it onto the end of hte list of push topics we'd
// previous got from the query.
-(IBAction)addPushTopic:(id)sender {
    [newTopicController showSheetForWindow:mainWindow topicBlock:^(NSDictionary *newTopic) {
        NSLog(@"newTopic is %@", newTopic);
        if (newTopic == nil) return;
        [self.pushTopicsDataSource addObject:newTopic];
        [topicsTable reloadData];
    }];
}

// This is called after login, and it runs the query to populate the PushTopics table.
-(void)startPushTopicQuery {
    [self query:@"select name, query, apiVersion from pushTopic order by name" doneBlock:^(NSDictionary *qr) {
        self.pushTopicsDataSource = [[[PushTopicsDataSource alloc] initWithRows:[qr objectForKey:@"records"] delegate:self] autorelease];
        [topicsTable setDataSource:self.pushTopicsDataSource];
    }];
}

// We're a delegate to the LoginController, it will call this once its sucessfully authenticated the user
// We create a StreamingApiClient and start the API query to get the list of PushTopics that can be subscribed to.
-(void)authenticated:(NSString *)sid onInstance:(NSURL *)instanceUrl {
    [[NSApp delegate] setSessionId:sid];
    [[NSApp delegate] setInstanceUrl:instanceUrl];
    self.client = [[[StreamingApiClient alloc] initWithSessionId:sid instance:instanceUrl] autorelease];
    self.client.delegate = self;
    [self startPushTopicQuery];
}

// Called when the user clicks the Clear button above the Events table, we just clear out of list of collected events.
-(IBAction)clearEvents:(id)sender {
    [events removeAllObjects];
    [eventTable reloadData];
}

// The StreamingApiClient will call this when it gets a new event on a data channel
// We add it to our list of events and force the table to update.
-(void)eventOnChannel:(NSString *)eventChannel message:(NSDictionary *)eventMessage {
    [events insertObject:eventMessage atIndex:0];
    [eventTable reloadData];
}

// The PushTopicsDataSource will call this when the user clicks on subscribe in the PushTopics table
// we just forward the subscribe request onto the StreamingApiClient, this will start the connection
// process the first time we try and subscribe.
-(void)subscribeTo:(NSString *)subscription {
    [self.client subscribe:subscription];
}

// The PushTopicsDataSource will call this when the user clicks on unsubscribe in the PushTopics table
// we tell the StreamingApiClient to unsubscribe.
-(void)unsubscribeFrom:(NSString *)subscription {
    [self.client unsubscribe:subscription];
}

// Called as the connection state of the StreamingApiClient changes, we map this into
// a string description of each state, which is shown in the bottom of the UI.
-(void)stateChangedTo:(StreamingApiState)newState {
    switch (newState) {
        case sacDisconnected: self.stateDescription = @"Disconnected"; break;
        case sacConnecting:   self.stateDescription = @"Connecting"; break;
        case sacConnected:    self.stateDescription = @"Connected"; break;
        case sacDisconnecting:self.stateDescription = @"Disconnecting"; break;
    }
}

// This is the DataSource protocol for the Events table
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return events.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *e = [events objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"when"]) {
        NSDate *date = [dateFormatter dateFromString:[e objectForKey:@"eventCreatedDate"]];
        return date;
    }
    return [e JSONRepresentation];
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([eventTable selectedRow] == -1) return;
    NSDictionary *row = [events objectAtIndex:[eventTable selectedRow]];
    [detailsDataSource setEvent:row];
    if (![detailsWindow isVisible]) {
        NSRect mw = [mainWindow frame];
        NSRect dw = [detailsWindow frame];
        dw.origin.x = mw.origin.x + mw.size.width;
        dw.origin.y = mw.origin.y;
        [detailsWindow orderFront:self];
        [detailsWindow setFrame:dw display:YES animate:YES];
    }
}

@end
