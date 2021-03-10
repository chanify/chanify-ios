//
//  UIViewController+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "UIViewController+CHExt.h"
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIImage.h>
#import "CHRouter.h"

@implementation UIViewController (CHExt)

- (instancetype)topViewController {
    UIViewController *presentedViewController = self.presentedViewController;
    if (presentedViewController == nil) {
        return self;
    }
    if ([presentedViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigationController = (UINavigationController *)presentedViewController;
        UIViewController *lastViewController = [navigationController.viewControllers lastObject];
        if (lastViewController != nil) {
            return lastViewController.topViewController;
        }
    }
    return presentedViewController.topViewController;
}

- (UINavigationController *)navigation {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    return navigationController;
}

- (UIBarButtonItem *)closeButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark"] style:UIBarButtonItemStylePlain target:self action:@selector(actionClose:)];
}

- (void)closeAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion {
    [CHRouter.shared closeViewController:self animated:animated completion:completion];
}

#pragma mark - Action Methods
- (void)actionClose:(id)sender {
    [self closeAnimated:YES completion:nil];
}


@end
