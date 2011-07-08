//
//  streamingTestAppDelegate.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import "streamingTestAppDelegate.h"
#import "LoginController.h"

@implementation streamingTestAppDelegate

@synthesize window, sessionId, instanceUrl;

+(NSSet *)keyPathsForValuesAffectingLoggedIn {
    return [NSSet setWithObject:@"sessionId"];
}

-(BOOL)loggedIn {
    return [self.sessionId length] > 0;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [login showSheet:self.window];
}

@end
