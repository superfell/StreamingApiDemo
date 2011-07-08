//
//  PushTopicsDataSource.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PushTopicsDataSource.h"


@implementation PushTopicsDataSource

- (id)initWithRows:(NSArray *)r {
    self = [super init];
    rows = [r mutableCopy];
    return self;
}

- (void)dealloc {
    [rows release];
    [super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [rows count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *r = [rows objectAtIndex:row];
    return [r objectForKey:[tableColumn identifier]];
}

-(void)addObject:(NSDictionary *)row {
    [rows addObject:row];
}

@end
