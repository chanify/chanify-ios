//
//  NSProgressIndicator+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSProgressIndicator+CHExt.h"

@implementation NSProgressIndicator (CHExt)

- (CGFloat)progress {
    return self.doubleValue;
}

- (void)setProgress:(CGFloat)progress {
    self.doubleValue = progress;
}

- (instancetype)initWithProgressViewStyle:(NSProgressIndicatorStyle)style {
    if (self = [super init]) {
        self.style = style;
    }
    return self;
}

- (void)setTrackTintColor:(NSColor *)trackTintColor {
    self.controlTint = NSBlueControlTint;
}


@end
