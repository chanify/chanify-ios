//
//  CHMessageCellItem.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHMessageCellItem.h"

@interface CHTapGestureRecognizer () <NSGestureRecognizerDelegate>

@end

@implementation CHTapGestureRecognizer

- (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action {
    if (self = [super initWithTarget:target action:action]) {
        self.delegate = self;
    }
    return self;
}

- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer {
    [self shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(NSGestureRecognizer *)gestureRecognizer {
    NSView *view = gestureRecognizer.view;
    SEL selector = NSSelectorFromString(@"canGestureRecognizer:");
    if ([view respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return ([view performSelector:selector withObject:gestureRecognizer] != nil);
#pragma clang diagnostic pop
    }
    return YES;
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
