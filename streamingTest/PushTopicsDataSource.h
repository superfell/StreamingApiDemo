//
//  PushTopicsDataSource.h
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PushTopicsDataSource : NSObject <NSTableViewDataSource> {
    NSMutableArray *rows;
    NSMutableSet   *subscriptions;
}

-(id)initWithRows:(NSArray *)rows;

-(void)addObject:(NSDictionary *)row;
-(NSDictionary *)objectAtIndex:(NSUInteger)row;

@end
