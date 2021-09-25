//
//  CHSplitViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/10.
//

#import "CHSplitViewController.h"
#import "CHTabBarViewController.h"
#import "CHViewController.h"
#import "CHTheme.h"

@interface CHSplitViewController ()

@property (nonatomic, readonly, strong) CHTabBarViewController *tabBarViewController;
@property (nonatomic, nullable, weak) UIViewController *lastSelectedViewController;
@property (nonatomic, readonly, strong) UINavigationController *emptyViewController;
@property (nonatomic, nullable, weak) UINavigationController *detailViewController;
@property (nonatomic, readonly, strong) NSMapTable<NSNumber *, UINavigationController*> *detailCache;

@end

@implementation CHSplitViewController

- (instancetype)init {
    if (self = [super init]) {
        _detailCache = [NSMapTable strongToStrongObjectsMapTable];
        _tabBarViewController = [CHTabBarViewController new];
        _emptyViewController = [UINavigationController new];
        self.emptyViewController.view.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        _detailViewController = nil;
        _lastSelectedViewController = nil;
        self.viewControllers = @[ self.tabBarViewController, self.emptyViewController ];
        self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    }
    return self;
}

- (void)resetDetailViewController {
    [self.detailCache removeObjectForKey:@(self.tabBarViewController.selectedIndex)];
    self.detailViewController = self.emptyViewController;
    self.viewControllers = @[ self.tabBarViewController, self.detailViewController ];
}

- (void)shouldChangeDetailViewControllerTo:(UIViewController *)vc {
    if (self.lastSelectedViewController != vc) {
        _lastSelectedViewController = vc;
        [self.detailCache setObject:self.detailViewController forKey:@(self.tabBarViewController.selectedIndex)];
        NSInteger index = [self.tabBarViewController.viewControllers indexOfObject:vc];
        self.detailViewController = [self.detailCache objectForKey:@(index)];
        if (self.detailViewController == nil) {
            self.detailViewController = self.emptyViewController;
        }
        self.viewControllers = @[ self.tabBarViewController, self.detailViewController ];
    }
}

- (BOOL)showDetailViewController:(nullable UIViewController *)vc params:(nullable NSDictionary *)params {
    if (vc == nil) {
        self.detailViewController = self.emptyViewController;
    } else {
        if (self.detailViewController != nil) {
            UIViewController *topVC = self.detailViewController.topViewController;
            if ([topVC isKindOfClass:CHViewController.class] && [vc.class isEqual:topVC.class] && [(CHViewController *)topVC isEqualWithParameters:params ?: @{}]) {
                return YES;
            }
        }
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
