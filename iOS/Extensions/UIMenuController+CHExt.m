//
//  UIMenuController+CHExt.m
//  iOS
//
//  Created by WizJin on 2021/6/8.
//

#import "UIMenuController+CHExt.h"

@implementation UIMenuController (CHExt)

- (void)showMenuFromView:(UIView *)targetView target:(UIView *)target point:(CGPoint)point {
    [target becomeFirstResponder];
    [self showMenuFromView:targetView rect:targetView.bounds];
}


@end
