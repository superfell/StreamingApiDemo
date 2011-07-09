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

// These are some helper URLConnection delegate implementations that will
// collect up the response data and present it in a single call
// the 1st one is designed to be subclassed
// the 2nd one uses a block to handle the completed request.

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
