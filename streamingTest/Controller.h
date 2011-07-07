//
//  Controller.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Controller : NSObject {
}

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *channel;

@property (retain) NSString *sessionId;
@property (retain) NSString *instance;

-(IBAction)login:(id)sender;

-(IBAction)start:(id)sender;
-(IBAction)stop:(id)sender;

@end
