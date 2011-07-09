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

#import "LoginController.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"

static NSString *OAUTH_CLIENT_ID = @"3MVG99OxTyEMCQ3hP1_9.Mh8dF_2HjgFbWgjolmyZp4c1MQ7_J7af1XXPjvW2HXv74c83GbUKEdIcn8S3M7KI";
static NSString *OAUTH_CLIENT_SECRET = @"7341320423187854498";

@implementation LoginController

@synthesize username, password, delegate, isAuthenticating;

+(NSSet *)keyPathsForValuesAffectingCanLogin {
    return [NSSet setWithObjects:@"username", @"password", nil];
}

-(void)showSheet:(NSWindow *)docWindow {
    self.isAuthenticating = NO;
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"last_username"];
    [NSApp beginSheet:window modalForWindow:docWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(BOOL)canLogin {
    return ([self.username length] > 0) && ([self.password length] > 0);
}

-(IBAction)login:(id)sender {
    self.isAuthenticating = YES;
    // send a POST request of the OAuth2 username/password flow to the Token endpoint
    // TODO it'd be better to use the regular web oauth flow instead of this.
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
        // Parse the response, and either show an error message to the user, or fire the authenticated delegate method.
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
            [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"last_username"];
        } else {
            NSLog(@"login %@", o);
            NSString *msg = [o objectForKey:@"error_description"];
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
