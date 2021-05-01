//
//  CHSplitViewController.h
//  Chanify
//
//  Created by WizJin on 2021/3/10.
//

#import <UIKit/UIKit.h>
#import "CHRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHSplitViewController : UISplitViewController<CHMainViewController>

@property (nonatomic, readonly, nullable, weak) UINavigationController *detailViewController;

- (BOOL)showDetailViewController:(nullable UIViewController *)vc;


@end

NS_ASSUME_NONNULL_END
