//
//  UrlConnectionDelegate.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/28/11.
//

#import <Foundation/Foundation.h>

@interface UrlConnectionDelegate : NSObject {
    NSMutableData       *data;
    NSHTTPURLResponse   *response;
    NSError             *error;
}

@property (retain,readonly) NSMutableData     *data;
@property (retain,readonly) NSHTTPURLResponse *response;
@property (retain,readonly) NSError           *error;
@property (readonly) NSUInteger                httpStatusCode;
@end

typedef void (^UrlCompletionBlock)(NSUInteger httpStatusCode, NSHTTPURLResponse *response, NSData *body, NSError *err);

@interface UrlConnectionDelegateWithBlock : UrlConnectionDelegate {
    UrlCompletionBlock  completionBlock;
    dispatch_queue_t    queueToRunBlock;
}

// will run the completion block on the specified queue
+(id)urlDelegateWithBlock:(UrlCompletionBlock)doneBlock queue:(dispatch_queue_t)queue;

// if useMain is false, the block will be run on the queue that makes this call,
// if useMain is true, the block will always be run on the main queue
+(id)urlDelegateWithBlock:(UrlCompletionBlock)doneBlock runOnMainThread:(BOOL)useMain;

@property (copy) UrlCompletionBlock  completionBlock;

@end