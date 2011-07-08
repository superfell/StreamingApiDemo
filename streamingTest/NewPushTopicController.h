//
//  NewPushTopicController.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import <Foundation/Foundation.h>


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

-(void)showSheetForWindow:(NSWindow *)window;

@end
