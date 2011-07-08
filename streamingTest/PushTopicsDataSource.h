//
//  PushTopicsDataSource.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

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
