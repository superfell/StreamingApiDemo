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

#import "UrlConnectionDelegate.h"

@interface UrlConnectionDelegate ()
@property (retain) NSMutableData     *data;
@property (retain) NSHTTPURLResponse *response;
@property (retain) NSError           *error;
@end

@implementation UrlConnectionDelegate

@synthesize data, response, error;

-(void)dealloc {
    [response release];
    [data release];
    [error release];
    [super dealloc];
}

-(void)connectionRequestEnded:(NSURLConnection *)connection {
    // subclasses should implmement
}

-(NSUInteger)httpStatusCode {
    return [self.response statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse {
    // start collecting up the response data.
    self.response = (NSHTTPURLResponse *)urlResponse;
    self.data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
    self.error = err;
    [self connectionRequestEnded:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    [self.data appendData:d];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // we've gotten all the response data.
    [self connectionRequestEnded:connection];
}

@end

@implementation UrlConnectionDelegateWithBlock

@synthesize completionBlock;

+(id)urlDelegateWithBlock:(UrlCompletionBlock)doneBlock queue:(dispatch_queue_t)queue {
    UrlConnectionDelegateWithBlock *d = [[UrlConnectionDelegateWithBlock alloc] init];
    d.completionBlock = doneBlock;
    d->queueToRunBlock = queue;
    return [d autorelease];
}

+(id)urlDelegateWithBlock:(UrlCompletionBlock) doneBlock runOnMainThread:(BOOL)useMain {
    dispatch_queue_t q = useMain ? dispatch_get_main_queue() : dispatch_get_current_queue();
    return [self urlDelegateWithBlock:doneBlock queue:q];
}

-(void)dealloc {
    [completionBlock release];
    [super dealloc];
}

- (void)connectionRequestEnded:(NSURLConnection *)connection {
    // we've gotten all the response data, run the completion block.
    dispatch_async(queueToRunBlock, ^(void) {
        self.completionBlock(self.httpStatusCode, self.response, self.data, self.error);
    });
}

@end