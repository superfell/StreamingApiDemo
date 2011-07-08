//
//  LoginController.h
//  streamingTest
//
//  Created by Simon Fell on 7/8/11.
//

#import <Foundation/Foundation.h>

@protocol LoginControllerDelegate <NSObject>
-(void)authenticated:(NSString *)sessionId onInstance:(NSURL *)instance;
@end

@interface LoginController : NSObject {
    IBOutlet NSWindow *window;
}

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (assign) BOOL isAuthenticating;

@property (assign) IBOutlet NSObject<LoginControllerDelegate> *delegate;

-(IBAction)login:(id)sender;
-(IBAction)cancel:(id)sender;

-(void)showSheet:(NSWindow *)docWindow;

@end
