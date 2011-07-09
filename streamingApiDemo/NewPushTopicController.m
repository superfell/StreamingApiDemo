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

#import "NewPushTopicController.h"
#import "StreamingApiDemoAppDelegate.h"
#import "NSObject+SBJson.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"

@implementation NewPushTopicController

@synthesize  name,query,description, showSpinner, createdTopic;

+(NSSet *)keyPathsForValuesAffectingCanSave {
    return [NSSet setWithObjects:@"name", @"query", nil];
}

-(void)dealloc {
    self.name = nil;
    self.query = nil;
    self.description = nil;
    [super dealloc];
}

-(void)showSheetForWindow:(NSWindow *)docWindow topicBlock:(NewTopicBlock)block {
    self.showSpinner = NO;
    self.createdTopic = nil;
    [NSApp beginSheet:window modalForWindow:docWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:Block_copy(block)];
}

-(BOOL)canSave {
    return ([name length] > 0) && ([query length] > 0);
}

-(void)save:(id)sender {
    // Build a POST request to the REST API to create the new PushTopic object.
    NSDictionary *topic = [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"Name", 
                           self.query, @"Query", 
                           @"22.0", @"ApiVersion", 
                           self.description, @"Description", nil];
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/services/data/v22.0/sobjects/pushTopic" relativeToURL:[[NSApp delegate] instanceUrl]]];
    [r setValue:[NSString stringWithFormat:@"OAuth %@", [[NSApp delegate] sessionId]] forHTTPHeaderField:@"Authorization"];
    [r setHTTPMethod:@"POST"];
    [r setHTTPBody:[[topic JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
    [r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [r setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    UrlConnectionDelegateWithBlock *d = [UrlConnectionDelegateWithBlock urlDelegateWithBlock:^(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err) {
        self.showSpinner = NO;
        if (httpStatusCode == 201) {
            self.createdTopic = topic;
            [NSApp endSheet:window returnCode:0];
            return;
        }
        SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
        NSArray *errors = [p objectWithData:body];
        NSLog(@"got error %@", errors);
        NSDictionary*e = [errors objectAtIndex:0];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Failed to create push topic" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil 
                                           otherButton:nil 
                             informativeTextWithFormat:[e objectForKey:@"message"]];
        [alert runModal];
        
    } runOnMainThread:YES];
    self.showSpinner = YES;
    [[[NSURLConnection alloc] initWithRequest:r delegate:d startImmediately:YES] autorelease];
}

-(void)cancel:(id)sender {
    [NSApp endSheet:window returnCode:1];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NewTopicBlock b = contextInfo;
    if (returnCode == 0)
        b(self.createdTopic);

    Block_release(b);
    [sheet orderOut:self];
}

@end
