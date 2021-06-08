//
//  UIButton+CHExt.m
//  iOS
//
//  Created by WizJin on 2021/6/8.
//

#import "UIButton+CHExt.h"
#import <UIKit/UILabel.h>

@implementation UIButton (CHExt)

+ (instancetype)button {
    return [self.class buttonWithType:UIButtonTypeCustom];
}

- (void)setTitleFont:(UIFont *)font {
    self.titleLabel.font = font;
}

- (void)setTitleTintColor:(UIColor *)color {
    [self setTitleColor:color forState:UIControlStateNormal];
}

- (void)setTitleSelectColor:(UIColor *)color {
    [self setTitleColor:color forState:UIControlStateSelected];
    [self setTitleColor:color forState:UIControlStateHighlighted];
}

- (void)setNormalTitle:(NSString *)normalTitle {
    [self setTitle:normalTitle forState:UIControlStateNormal];
}

- (void)addTarget:(nullable id)target action:(SEL)action {
    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}


@end
