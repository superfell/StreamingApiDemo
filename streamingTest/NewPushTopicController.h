//
//  NewPushTopicController.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>

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

-(void)showSheetForWindow:(NSWindow *)docWindow topicBlock:(NewTopicBlock)block;

@end
