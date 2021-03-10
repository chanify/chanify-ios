//
//  CHSplitViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/10.
//

#import "CHSplitViewController.h"
#import "CHTabBarViewController.h"
#import "CHTheme.h"

@interface CHSplitViewController ()

@property (nonatomic, readonly, strong) CHTabBarViewController *tabBarViewController;
@property (nonatomic, readonly, strong) UINavigationController *emptyViewController;
@property (nonatomic, nullable, weak) UINavigationController *detailViewController;

@end

@implementation CHSplitViewController

- (instancetype)init {
    if (self = [super init]) {
        _tabBarViewController = [CHTabBarViewController new];
        _emptyViewController = [UINavigationController new];
        self.emptyViewController.view.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        _detailViewController = nil;
        self.viewControllers = @[ self.tabBarViewController, self.emptyViewController ];
        self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    }
    return self;
}

- (BOOL)showDetailViewController:(nullable UIViewController *)vc {
    if (vc == nil) {
        self.detailViewController = self.emptyViewController;
    } else {
        if ([vc isKindOfClass:UINavigationController.class]) {
            self.detailViewController = (UINavigationController *)vc.navigation;
        } else {
            self.detailViewController = vc.navigation;
        }
    }
    self.viewControllers = @[ self.tabBarViewController, self.detailViewController ];
    return YES;
}

#pragma mark - CHMainViewController
- (void)viewReset {
    [self.tabBarViewController viewReset];
}


@end
