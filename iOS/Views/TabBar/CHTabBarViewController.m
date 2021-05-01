//
//  CHTabBarViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTabBarViewController.h"
#import "CHTheme.h"

@interface CHTabBarViewController () <UITabBarControllerDelegate>

@end

@implementation CHTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = CHTheme.shared.backgroundColor;
    self.viewControllers = @[
        tabBarItemWithName(@"Channels", @"Channel"),
        tabBarItemWithName(@"Nodes", @"Network"),
        tabBarItemWithName(@"Settings", @"Settings"),
    ];
    self.delegate = self;
}

#pragma mark - UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [CHRouter.shared resetDetailViewController];
}

#pragma mark - CHMainViewController
- (void)viewReset {
    [self setSelectedIndex:0];
    if ([self.selectedViewController isKindOfClass:UINavigationController.class]) {
        [(UINavigationController *)self.selectedViewController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark - Private Methods
static inline UIViewController* tabBarItemWithName(NSString *name, NSString *image) {
    Class clz = NSClassFromString([NSString stringWithFormat:@"CH%@ViewController", name]);
    UIViewController *vc = [clz new];
    vc.title = name.localized;
    vc.tabBarItem.image = [UIImage imageNamed:image];
    return vc.navigation;
}


@end
