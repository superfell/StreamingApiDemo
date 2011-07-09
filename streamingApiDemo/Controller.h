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

#import <Foundation/Foundation.h>
#import "StreamingApiClient.h"
#import "PushTopicsDataSource.h"
#import "LoginController.h"

// This is the Controller for the primary UI window, it handles running the 
// query to get the list of PushTopics, and of routing subscribe/unsubscribe 
// clicks from the PushTopic table to the StreamingApiClient.

// It also listens for the Streaming Api Client events and displays those
// in the event list.

@class NewPushTopicController;

@interface Controller : NSObject <StreamingApiClientDelegate, NSTableViewDataSource, TableSubscribes, LoginControllerDelegate> {
    IBOutlet    NSTableView *eventTable, *topicsTable;
    IBOutlet    NewPushTopicController   *newTopicController;
    NSMutableArray                       *events;
    NSDateFormatter                      *dateFormatter;
}

@property (retain) StreamingApiClient   *client;
@property (retain) NSString             *stateDescription;
@property (retain) PushTopicsDataSource *pushTopicsDataSource;

-(IBAction)addPushTopic:(id)sender;
-(IBAction)clearEvents:(id)sender;

@end
