//
//  Controller.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>
#import "StreamingApiClient.h"
#import "PushTopicsDataSource.h"

@class NewPushTopicController;

@interface Controller : NSObject <StreamingApiClientDelegate, NSTableViewDataSource, TableSubscribes> {
    IBOutlet    NSTableView *eventTable, *topicsTable;
    IBOutlet    NewPushTopicController *newTopicController;
    NSMutableArray          *events;
}

@property (retain) StreamingApiClient *client;

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *channel;

@property (assign) BOOL loggedIn;
@property (retain) NSString *sessionId;
@property (retain) NSString *instance;

@property (retain) NSString *stateDescription;
@property (retain) PushTopicsDataSource *pushTopicsDataSource;

-(IBAction)login:(id)sender;
-(IBAction)start:(id)sender;
-(IBAction)stop:(id)sender;

-(IBAction)addPushTopic:(id)sender;
-(IBAction)clearEvents:(id)sender;

@end
