//
//  CHMessageCellItem.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHMessageCellItem.h"

@implementation CHTapGestureRecognizer

- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer {
}

@end

@implementation CHLongPressGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithTarget:target action:action]) {
        self.buttonMask = 0x02;    // Right button click
    }
    return self;
}

@end
