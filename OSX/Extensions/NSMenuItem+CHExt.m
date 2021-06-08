//
//  NSMenuItem+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSMenuItem+CHExt.h"

@implementation NSMenuItem (CHExt)

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action {
    if (self = [self init]) {
        self.title = title;
        self.action = action;
    }
    return self;
}

@end
