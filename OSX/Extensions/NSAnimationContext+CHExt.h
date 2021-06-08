//
//  NSAnimationContext+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import <AppKit/NSAnimationContext.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAnimationContext (CHExt)

+ (void)runningPropertyAnimatorWithDuration:(NSTimeInterval)duration
                                              delay:(NSTimeInterval)delay
                                            options:(NSUInteger)options
                                         animations:(void (^)(void))animations
                                 completion:(void (^ __nullable)(NSInteger finalPosition))completion;



@end

NS_ASSUME_NONNULL_END
