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

// This class is the controller for the Sheet/Window that allows the user
// to create a new PushTopic record.

typedef void (^NewTopicBlock)(NSDictionary *newTopic);

@interface NewPushTopicController : NSObject {
    IBOutlet NSWindow *window;
}

@property (retain) NSString *name;
@property (retain) NSString *query;
@property (retain) NSString *description;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@property (readonly) BOOL canSave;
@property (assign) BOOL showSpinner;
@property (retain) NSDictionary *createdTopic;

// Shows the NewTopic sheet on the 'docWindow' and will later execute the topicBlock
// if a new topic was created.
-(void)showSheetForWindow:(NSWindow *)docWindow topicBlock:(NewTopicBlock)block;

@end
