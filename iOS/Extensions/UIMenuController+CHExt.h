//
//  UIMenuController+CHExt.h
//  iOS
//
//  Created by WizJin on 2021/6/8.
//

#import <UIKit/UIMenuController.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIMenuController (CHExt)

- (void)showMenuFromView:(UIView *)targetView target:(UIView *)target point:(CGPoint)point;


@end

NS_ASSUME_NONNULL_END
