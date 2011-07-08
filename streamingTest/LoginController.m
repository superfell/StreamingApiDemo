//
//  LoginController.m
//  streamingTest
//
//  Created by Simon Fell on 7/8/11.
//

#import "LoginController.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"

static NSString *OAUTH_CLIENT_ID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF_2HjgFbWgjolmyZp4c1MQ7_J7af1XXPjvW2HXv74c83GbUKEdIcn8S3M7KI";
static NSString *OAUTH_CLIENT_SECRET = @"7341320423187854498";

@implementation LoginController

@synthesize username, password, delegate, isAuthenticating;

-(void)showSheet:(NSWindow *)docWindow {
    self.isAuthenticating = NO;
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"last_username"];
    [NSApp beginSheet:window modalForWindow:docWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)login:(id)sender {
    self.isAuthenticating = YES;
    NSString *params = [NSString stringWithFormat:@"grant_type=password&client_id=%@&client_secret=%@&username=%@&password=%@",
                        [OAUTH_CLIENT_ID stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                        [OAUTH_CLIENT_SECRET stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                        [self.username stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                        [self.password stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:@"https://login.salesforce.com/services/oauth2/token"];
    
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:url];
    [r setHTTPMethod:@"POST"];
    [r setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    UrlConnectionDelegateWithBlock *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        self.isAuthenticating = NO;
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        NSDictionary *o = [p objectWithData:body];
        NSString *e = [o objectForKey:@"error"];
        if (e == nil) {
            NSString *sid = [o objectForKey:@"access_token"];
            NSURL *instance = [NSURL URLWithString:[o objectForKey:@"instance_url"]];
            [delegate authenticated:sid onInstance:instance];
            [NSApp endSheet:window returnCode:1];
            [window orderOut:sender];
        } else {
            NSString *msg = [o objectForKey:@"message"];
            NSAlert *alert = [NSAlert alertWithMessageText:@"Couldn't login" 
                                             defaultButton:@"OK" 
                                           alternateButton:nil 
                                               otherButton:nil 
                                 informativeTextWithFormat:msg];
            [alert runModal];
        }
        
    } runOnMainThread:YES];
    
    [[[NSURLConnection alloc] initWithRequest:r delegate:d startImmediately:YES] autorelease];
}

-(IBAction)cancel:(id)sender {
    [NSApp endSheet:window returnCode:0];
    [window orderOut:sender];
}

@end
