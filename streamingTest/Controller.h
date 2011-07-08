//
//  Controller.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>
#import "StreamingApiClient.h"


@interface Controller : NSObject <StreamingApiClientDelegate, NSTableViewDataSource> {
    IBOutlet    NSTableView *eventTable;
    NSMutableArray          *events;
}

@property (retain) StreamingApiClient *client;

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *channel;

@property (retain) NSString *sessionId;
@property (retain) NSString *instance;

@property (assign) BOOL connected;

-(IBAction)login:(id)sender;
-(IBAction)start:(id)sender;
-(IBAction)stop:(id)sender;

@end
