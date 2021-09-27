//
//  CHSegmentedControl.m
//  OSX
//
//  Created by WizJin on 2021/9/27.
//

#import "CHSegmentedControl.h"

@implementation CHSegmentedControl

- (instancetype)initWithItems:(NSArray<NSString *> *)items {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.segmentCount = items.count;
        NSInteger i = 0;
        for (NSString *title in items) {
            [self setLabel:title forSegment:i++];
        }
        self.alignment = NSTextAlignmentCenter;
        self.segmentStyle = NSSegmentStyleRounded;
    }
    return self;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
    self.selectedSegment = selectedSegmentIndex;
}

- (NSInteger)selectedSegmentIndex {
    return self.selectedSegment;
}

- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(CHControlEvents)controlEvents {
    self.target = target;
    self.action = action;
}


@end
