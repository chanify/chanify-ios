//
//  UIButton+CHExt.h
//  iOS
//
//  Created by WizJin on 2021/6/8.
//

#import <UIKit/UIButton.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (CHExt)

+ (instancetype)button;
- (void)setTitleFont:(UIFont *)font;
- (void)setTitleTintColor:(UIColor *)color;
- (void)setTitleSelectColor:(UIColor *)color;
- (void)setNormalTitle:(NSString *)normalTitle;
- (void)addTarget:(nullable id)target action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
