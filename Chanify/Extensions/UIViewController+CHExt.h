//
//  UIViewController+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UINavigationController.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (CHExt)

- (instancetype)topViewController;
- (UINavigationController *)navigation;
- (UIBarButtonItem *)closeButtonItem;
- (void)closeAnimated:(BOOL)animated completion: (void (^__nullable)(void))completion;


@end

NS_ASSUME_NONNULL_END
