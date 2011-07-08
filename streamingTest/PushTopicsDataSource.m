//
//  PushTopicsDataSource.m
//  streamingTest
//
//  Created by Simon Fell on 7/7/11.
//

#import "PushTopicsDataSource.h"


@implementation PushTopicsDataSource

- (id)initWithRows:(NSArray *)r {
    self = [super init];
    rows = [r mutableCopy];
    subscriptions = [[NSMutableSet alloc] init];
    return self;
}

- (void)dealloc {
    [rows release];
    [subscriptions release];
    [super dealloc];
}

-(void)addObject:(NSDictionary *)row {
    [rows addObject:row];
}

-(NSDictionary *)objectAtIndex:(NSUInteger)row {
    return [rows objectAtIndex:row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [rows count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *r = [rows objectAtIndex:row];
    NSString *col = [tableColumn identifier];
    id v = nil;
    if ([col isEqualToString:@"subscribed"])
        v = [NSNumber numberWithBool:[subscriptions containsObject:r]];
    else
        v = [r objectForKey:[tableColumn identifier]];
    NSLog(@"valForCol %@ row %ld => %@", tableColumn.identifier, row, v);
    return v;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSLog(@"setObjectValue:%@ forCol %@ row %ld", object, tableColumn.identifier, row);
    NSDictionary *r = [rows objectAtIndex:row];
    if ([object intValue] == 1)
        [subscriptions addObject:r];
    else
        [subscriptions removeObject:r];
}

@end
