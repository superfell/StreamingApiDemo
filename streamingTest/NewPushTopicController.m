//
//  NewPushTopicController.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NewPushTopicController.h"
#import "streamingTestAppDelegate.h"
#import "NSObject+SBJson.h"
#import "UrlConnectionDelegate.h"
#import "SBJsonParser.h"

@implementation NewPushTopicController

@synthesize  name,query,description, showSpinner, createdTopic;



+(NSSet *)keyPathsForValuesAffectingCanSave {
    return [NSSet setWithObjects:@"name", @"query", nil];
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.query = nil;
    self.description = nil;
    [super dealloc];
}

-(BOOL)canSave {
    return ([name length] > 0) && ([query length] > 0);
}

-(void)showSheetForWindow:(NSWindow *)docWindow topicBlock:(NewTopicBlock)block {
    self.showSpinner = NO;
    self.createdTopic = nil;
    [NSApp beginSheet:window modalForWindow:docWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:Block_copy(block)];
}

-(void)save:(id)sender {
    NSDictionary *topic = [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"Name", 
                           self.query, @"Query", 
                           @"22.0", @"ApiVersion", 
                           self.description, @"Description", nil];
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/services/data/v22.0/sobjects/pushTopic" relativeToURL:[[NSApp delegate] instanceUrl]]];
    [r setValue:[NSString stringWithFormat:@"OAuth %@", [[NSApp delegate] sessionId]] forHTTPHeaderField:@"Authorization"];
    [r setHTTPMethod:@"POST"];
    NSLog(@"topic %@", [topic JSONRepresentation]);
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
