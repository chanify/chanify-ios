//
//  CHTabBarViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTabBarViewController.h"
#import "CHTheme.h"

@implementation CHTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = CHTheme.shared.backgroundColor;
    self.viewControllers = @[
        tabBarItemWithName(@"Channels", @"Channel"),
        tabBarItemWithName(@"Settings", @"Settings"),
    ];
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
