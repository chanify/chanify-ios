//
//  CHSwitch.h
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHSwitch : NSSwitch

@property (nonatomic, assign) bool on;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(CHControlEvents)events;


@end

NS_ASSUME_NONNULL_END
