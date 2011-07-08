//
//  Controller.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>
#import "StreamingApiClient.h"
#import "PushTopicsDataSource.h"
#import "LoginController.h"

@class NewPushTopicController;

@interface Controller : NSObject <StreamingApiClientDelegate, NSTableViewDataSource, TableSubscribes, LoginControllerDelegate> {
    IBOutlet    NSTableView *eventTable, *topicsTable;
    IBOutlet    NewPushTopicController   *newTopicController;
    IBOutlet    LoginController          *loginController;
    NSMutableArray                       *events;
}

@property (retain) StreamingApiClient   *client;
@property (retain) NSString             *stateDescription;
@property (retain) PushTopicsDataSource *pushTopicsDataSource;

-(IBAction)addPushTopic:(id)sender;
-(IBAction)clearEvents:(id)sender;

@end
