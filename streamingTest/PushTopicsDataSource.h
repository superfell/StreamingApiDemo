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

// The PushTopicsDataSource class manages the list of PushTopics, and provides
// a data source implementation to bind them to the TableView.

// When the subscribe/unsubscribe buttons are clicked, these are translated
// into calls to the TableSubscribes delegate.
@protocol TableSubscribes <NSObject>
-(void)subscribeTo:(NSString *)subscription;
-(void)unsubscribeFrom:(NSString *)subscription;
@end

@interface PushTopicsDataSource : NSObject <NSTableViewDataSource> {
    NSMutableArray              *rows;
    NSMutableSet                *subscriptions;
    NSObject<TableSubscribes>   *delegate;
}

-(id)initWithRows:(NSArray *)rows delegate:(NSObject<TableSubscribes> *)delegate;

-(void)addObject:(NSDictionary *)row;
-(NSDictionary *)objectAtIndex:(NSUInteger)row;

@end
