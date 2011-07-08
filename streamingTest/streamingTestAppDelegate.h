//
//  streamingTestAppDelegate.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Cocoa/Cocoa.h>

@interface streamingTestAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow    *window;
    NSString    *sessionId;
    NSURL       *instanceUrl;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSString *sessionId;
@property (retain) NSURL *instanceUrl;

@end
