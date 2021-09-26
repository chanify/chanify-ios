//
//  CHSwitch.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHSwitch.h"

@implementation CHSwitch

- (void)setOn:(bool)on {
    self.state = on ? NSControlStateValueOn : NSControlStateValueOff;
}

- (bool)on {
    return self.state == NSControlStateValueOn;
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(CHControlEvents)events {
    self.target = target;
    self.action = action;
}


@end
