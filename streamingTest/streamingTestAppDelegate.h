//
//  streamingTestAppDelegate.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Cocoa/Cocoa.h>

@class LoginController;

@interface streamingTestAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow    *window;
    NSString    *sessionId;
    NSURL       *instanceUrl;
    
    IBOutlet LoginController *login;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSString *sessionId;
@property (retain) NSURL *instanceUrl;

-(BOOL)loggedIn;

@end
