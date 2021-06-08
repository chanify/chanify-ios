//
//  NSAnimationContext+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSAnimationContext+CHExt.h"
#import <QuartzCore/QuartzCore.h>
#import "CHUI.h"

@implementation NSAnimationContext (CHExt)

+ (void)runningPropertyAnimatorWithDuration:(NSTimeInterval)duration
                                              delay:(NSTimeInterval)delay
                                            options:(NSUInteger)options
                                         animations:(void (^)(void))animations
                                 completion:(void (^ __nullable)(NSInteger finalPosition))completion {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = duration;
        switch (options) {
            case UIViewAnimationOptionCurveEaseIn:
                context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                break;
            case UIViewAnimationOptionCurveEaseOut:
                context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                break;
        }
        animations();
    } completionHandler:^{
        if (completion != nil) {
            completion(0);
        }
    }];
}


@end
