//
//  CHRouter.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHRouter.h"
#import <MessageUI/MessageUI.h>
#import <JLRoutes/JLRoutes.h>
#import <Masonry/Masonry.h>
#import "CHTabBarViewController.h"
#import "CHLoginViewController.h"
#import "CHWebViewController.h"
#import "CHIndicatorPanelView.h"
#import "CHDevice.h"
#import "CHTheme.h"
#import "CHLogic.h"

@interface CHRouter () <MFMailComposeViewControllerDelegate>

@property (nonatomic, readonly, strong) JLRoutes *routes;

@end

@implementation CHRouter

+ (instancetype)shared {
    static CHRouter *router;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        router = [CHRouter new];
    });
    return router;
}

- (instancetype)init {
    if (self = [super init]) {
        _routes = [JLRoutes routesForScheme:@"_internal"];
        [self initRouters:self.routes];
    }
    return self;
}

- (void)active {
    [CHLogic.shared active];
}

- (void)deactive {
    [CHLogic.shared deactive];
}

- (BOOL)canSendMail {
    return MFMailComposeViewController.canSendMail;
}

- (BOOL)launchWithOptions:(NSDictionary *)options {
    [CHLogic.shared launch];

    UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window = window;
    window.backgroundColor = CHTheme.shared.backgroundColor;
    [self routeTo:@"/page/main"];
    [window makeKeyAndVisible];
    return YES;
}

- (BOOL)handleURL:(NSURL *)url {
    return [self routeTo:url.absoluteString withParams:nil];
}

- (BOOL)routeTo:(NSString *)url {
    return [self routeTo:url withParams:nil];
}

- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params {
    BOOL res = NO;
    if ([[params valueForKey:@"noauth"] boolValue] || CHLogic.shared.me != nil) {
        res = [self.routes routeURL:[NSURL URLWithString:url] withParameters:params];
    } else {
        res = [self.routes routeURL:[NSURL URLWithString:@"/page/login"]];
    }
    return res;
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    UIViewController *vc = self.window.rootViewController.topViewController;
    if ([vc isKindOfClass:UITabBarController.class]) {
        vc = [(UITabBarController *)vc selectedViewController];
    }
    if ([vc isKindOfClass:UINavigationController.class]) {
        [(UINavigationController *)vc popToRootViewControllerAnimated:animated];
    } else {
        [vc.navigationController popToRootViewControllerAnimated:animated];
    }
}

- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated {
    showViewController(viewController, animated, YES);
}

- (void)presentSystemViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController.topViewController presentViewController:viewController animated:animated completion:nil];
}

- (void)showIndicator:(BOOL)show {
    dispatch_main_async(^{
        showIndicator(show);
    });
}

- (void)makeToast:(NSString *)message {
    dispatch_main_async(^{
        showToast(message);
    });
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (UIWindow *)window {
    return UIApplication.sharedApplication.delegate.window;
}

- (void)setWindow:(UIWindow *)window {
    UIApplication.sharedApplication.delegate.window = window;
}

- (void)initRouters:(JLRoutes *)routes {
    [routes addRoute:@"/page/main" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        CHTabBarViewController *vc = (CHTabBarViewController *)setRootViewController(self.window, CHTabBarViewController.class);
        [vc setSelectedIndex:0];
        if ([vc.selectedViewController isKindOfClass:UINavigationController.class]) {
            [(UINavigationController *)vc.selectedViewController popToRootViewControllerAnimated:NO];
        }
        return YES;
    }];
    [routes addRoute:@"/page/login" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        setRootViewController(self.window, CHLoginViewController.class);
        return YES;
    }];
    [routes addRoute:@"/page/:name(/:subname)" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        BOOL res = NO;
        NSString *name = [parameters valueForKey:@"name"];
        NSString *subname = [parameters valueForKey:@"subname"];
        if (subname.length > 0) {
            name = [name stringByAppendingString:subname.code];
        }
        if (name.length > 0) {
            Class clz = NSClassFromString([NSString stringWithFormat:@"CH%@ViewController", name.code]);
            if ([clz isSubclassOfClass:UIViewController.class]) {
                if ([[parameters valueForKey:@"jump"] boolValue]) {
                    res = tryJumpViewController(clz);
                }
                NSString *show = [parameters valueForKey:@"show"];
                if (res == NO) {
                    UIViewController *vc = [clz alloc];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    if ([vc respondsToSelector:@selector(initWithParameters:)]) {
                        vc = [vc performSelector:@selector(initWithParameters:) withObject:parameters];
                    } else {
                        vc = [vc init];
                    }
#pragma clang diagnostic pop
                    res = showViewController(vc, YES, ![show isEqualToString:@"present"]);
                }
            }
        }
        return res;
    }];
    [routes addRoute:@"/action/openurl" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSString *url = [parameters valueForKey:@"url"];
        if (url.length > 0) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
            res = YES;
        }
        return res;
    }];
    [routes addRoute:@"/action/sendemail" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSString *email = [parameters valueForKey:@"email"];
        if (email.length > 0 && MFMailComposeViewController.canSendMail) {
            MFMailComposeViewController *mailVC = [MFMailComposeViewController new];
            if (mailVC != nil) {
                mailVC.mailComposeDelegate = self;
                mailVC.title = @"Feedback".localized;
                [mailVC setToRecipients:@[email]];
                [mailVC setSubject:[NSString stringWithFormat:@"[%@] %@", CHDevice.shared.app, mailVC.title]];
                res = showViewController(mailVC, YES, NO);
            }
        }
        return res;
    }];
    routes.unmatchedURLHandler = ^(JLRoutes *routes, NSURL *url, NSDictionary<NSString *, id> *parameters) {
        NSString *scheme = url.scheme;
        if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
            if (showViewController([[CHWebViewController alloc] initWithUrl:url parameters:parameters], YES, YES)) {
                return;
            }
        }
        [self makeToast:@"Can't open url".localized];
    };
}

static inline UIViewController *setRootViewController(UIWindow *window, Class clz) {
    UIViewController *rootVC = window.rootViewController;
    if (![rootVC isKindOfClass:clz]) {
        rootVC = [clz new];
        NSTimeInterval duration = (window.rootViewController == nil ? 0 : kCHAnimateMediumDuration);
        [UIView transitionWithView:window duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            BOOL oldState = UIView.areAnimationsEnabled;
            [UIView setAnimationsEnabled:NO];
            window.rootViewController = rootVC;
            [UIView setAnimationsEnabled:oldState];
        } completion:nil];
    }
    if (rootVC.presentationController != nil) {
        [rootVC dismissViewControllerAnimated:NO completion:nil];
    }
    return rootVC;
}

static inline BOOL showViewController(UIViewController *vc, BOOL animated, BOOL tryPush) {
    return showViewControllerToVC(vc, CHRouter.shared.window.rootViewController, animated, tryPush);
}

static inline BOOL showViewControllerToVC(UIViewController *vc, UIViewController *rootViewController, BOOL animated, BOOL tryPush) {
    UIViewController *topViewController = rootViewController.topViewController;
    if (tryPush) {
        BOOL hiddenBottomBar = NO;
        if ([topViewController isKindOfClass:UITabBarController.class]) {
            topViewController = ((UITabBarController *)topViewController).selectedViewController;
            hiddenBottomBar = YES;
        }
        UINavigationController *navigationController = nil;
        if ([topViewController isKindOfClass:UINavigationController.class]) {
            navigationController = (UINavigationController *)topViewController;
        } else if (topViewController.navigationController != nil) {
            navigationController = topViewController.navigationController;
        }
        if (navigationController != nil) {
            vc.hidesBottomBarWhenPushed = hiddenBottomBar;
            UIImage *indicatorImage = CHTheme.shared.backImage;
            if (![indicatorImage isEqual:navigationController.navigationBar.backIndicatorImage]) {
                navigationController.navigationBar.backIndicatorImage = indicatorImage;
                navigationController.navigationBar.backIndicatorTransitionMaskImage = indicatorImage;
            }
            navigationController.navigationBar.topItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
            [navigationController pushViewController:vc animated:animated];
            return YES;
        }
    }
    return presentViewControllerToVC(vc, topViewController, animated);
}

static inline BOOL presentViewControllerToVC(UIViewController *vc, UIViewController *topViewController, BOOL animaied) {
    UINavigationController *navigationController = ([vc isKindOfClass:UINavigationController.class] ? (UINavigationController *)vc : vc.navigation);
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [topViewController presentViewController:navigationController animated:animaied completion:nil];
    NSArray *items = navigationController.navigationBar.topItem.leftBarButtonItems;
    NSMutableArray *leftItems = [NSMutableArray arrayWithCapacity:items.count + 1];
    [leftItems addObject:vc.closeButtonItem];
    [leftItems addObjectsFromArray:items];
    navigationController.navigationBar.topItem.leftBarButtonItems = leftItems;
    return YES;
}

static inline BOOL tryJumpViewController(Class clz) {
    UIViewController *rootViewController = CHRouter.shared.window.rootViewController;
    UIViewController *vc = rootViewController.topViewController;
    if ([vc isKindOfClass:clz]) return YES;
    if (vc.presentationController != nil) {
        if ([vc.presentationController isKindOfClass:clz]) return YES;
        // TODO: Check presentation controller
        [vc dismissViewControllerAnimated:NO completion:nil];
    }
    if ([rootViewController isKindOfClass:CHTabBarViewController.class]) {
        CHTabBarViewController *tabVC = (CHTabBarViewController *)rootViewController;
        if ([tabVC.selectedViewController.topViewController isKindOfClass:clz]) {
            return YES;
        }
        UINavigationController *nav = nil;
        if ([tabVC.selectedViewController isKindOfClass:UINavigationController.class]) {
            nav = tabVC.selectedViewController;
        } else {
            nav = [tabVC.selectedViewController navigationController];
        }
        if (nav != nil) {
            for (UIViewController *vc in nav.viewControllers) {
                if ([vc isKindOfClass:clz]) {
                    [nav popToViewController:vc animated:NO];
                    return YES;
                }
            }
        }
        for (UIViewController *vc in tabVC.viewControllers) {
            if ([vc.topViewController isKindOfClass:clz]) {
                [nav popToRootViewControllerAnimated:NO];
                [tabVC setSelectedViewController:vc];
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Indicator Helper
static inline void showIndicator(BOOL show) {
    static CHIndicatorPanelView *alert = nil;
    if (!show) {
        if (alert != nil) {
            [alert stopAnimating];
            alert = nil;
        }
    } else {
        if (alert == nil) {
            alert = [CHIndicatorPanelView new];
            [CHRouter.shared.window addSubview:alert];
            [alert startAnimating];
        }
    }
}

#pragma mark - Toast Helper
static inline void showToast(NSString *message) {
    static const CGFloat radius = 14.0;

    NSTimeInterval delay = 0;

    static UILabel *lastToast = nil;
    if (lastToast != nil) {
        delay += 0.2;
        closeToast(lastToast, 0);
        lastToast = nil;
    }
    
    UIView *view = CHRouter.shared.window;
    UILabel *toast = [UILabel new];
    [view addSubview:(lastToast = toast)];
    toast.text = message;
    toast.alpha = 0;
    toast.numberOfLines = 1;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14];
    toast.textColor = UIColor.whiteColor;
    toast.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.8];
    toast.layer.cornerRadius = radius;
    toast.clipsToBounds = YES;

    CGSize size = [toast sizeThatFits:CGSizeMake(UIScreen.mainScreen.bounds.size.width * 0.8, radius * 2)];
    size.height = radius * 2;
    size.width += floor(radius * 2);
    size.width = fmax(size.width, radius * 4);
    
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(view.mas_safeAreaLayoutGuideBottom).offset(-60);
        make.centerX.equalTo(view);
        make.size.mas_equalTo(size);
    }];

    openToast(toast, delay);
    dispatch_main_after(2.0, ^{
        closeToast(toast, delay);
    });
}

static inline void openToast(UILabel *toast, NSTimeInterval delay) {
    [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateFastDuration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
        toast.alpha = 1;
    } completion:nil];
}

static inline void closeToast(UILabel *toast, NSTimeInterval delay) {
    [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateFastDuration delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.alpha = 0;
    } completion:^(UIViewAnimatingPosition finalPosition) {
        [toast removeFromSuperview];
    }];
}


@end
