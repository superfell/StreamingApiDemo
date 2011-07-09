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
#import "DetailsDataSource.h"


@implementation DetailsDataSource

- (void)dealloc {
    [event release];
    [keys release];
    [super dealloc];
}

-(NSDictionary *)event {
    return event;
}

-(void)setEvent:(NSDictionary *)e {
    [event autorelease];
    event = [e retain];
    [keys autorelease];
    NSArray *a = [[event allKeys] sortedArrayUsingSelector:@selector(compare:)];
    keys = [a retain];
    [table reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return keys.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *k = [keys objectAtIndex:row];
    NSString *i = [tableColumn identifier];
    if ([i isEqualToString:@"key"])
        return k;
    return [event objectForKey:k];
}

@end
