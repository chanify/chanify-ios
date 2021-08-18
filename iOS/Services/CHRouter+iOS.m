//
//  CHRouter+iOS.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHRouter+iOS.h"
#import <MessageUI/MessageUI.h>
#import <JLRoutes/JLRoutes.h>
#import <Masonry/Masonry.h>
#import "CHTabBarViewController.h"
#import "CHSplitViewController.h"
#import "CHLoginViewController.h"
#import "CHWebViewController.h"
#import "CHIndicatorPanelView.h"
#import "CHPasteboard.h"
#import "CHToken.h"
#import "CHDevice.h"
#import "CHLogic.h"
#import "CHTheme.h"

typedef NS_ENUM(NSInteger, CHRouterShowMode) {
    CHRouterShowModePush    = 0,
    CHRouterShowModePresent = 1,
    CHRouterShowModeDetail  = 2,
};

@interface CHRouter () <MFMailComposeViewControllerDelegate>

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
        [self initRouters:JLRoutes.globalRoutes];
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
    UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window = window;
    window.backgroundColor = CHTheme.shared.backgroundColor;

    [CHLogic.shared launch];

    [self routeTo:@"/page/main"];
    [window makeKeyAndVisible];
    return YES;
}

- (BOOL)handleShortcut:(NSString *)type {
    BOOL res = NO;
    if (type.length > 0) {
        if ([type isEqualToString:@"scan"]) {
            res = [self routeTo:@"/page/scan?show=present&jump=1"];
        }
    }
    return res;
}

- (BOOL)handleURL:(NSURL *)url {
    NSString *target = url.absoluteString;
    NSDictionary *params = nil;
    if ([url.scheme isEqualToString:@"chanify"]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:target];
        if ([url.path isEqualToString:@"/action/scan"]) {
            target = @"/page/scan?show=present&jump=1";
        } else if ([url.path isEqualToString:@"/page/channel"]) {
            NSString *cid = [components queryValueForName:@"cid"];
            if (cid.length <= 0) {
                return NO;
            }
            target = url.path;
            params = @{ @"show": @"detail", @"singleton": @YES, @"cid": cid };
        }
    }
    return [self routeTo:target withParams:params];
}

- (BOOL)routeTo:(NSString *)url {
    return [self routeTo:url withParams:nil];
}

- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params {
    BOOL res = NO;
    if ([[params valueForKey:@"singleton"] boolValue]) {
        [self popToRootViewControllerAnimated:NO];
    }
    if ([[params valueForKey:@"noauth"] boolValue] || CHLogic.shared.me != nil) {
        res = [JLRoutes routeURL:[NSURL URLWithString:url] withParameters:params];
    } else {
        res = [JLRoutes routeURL:[NSURL URLWithString:@"/page/login"]];
    }
    return res;
}

- (void)resetDetailViewController {
    UIViewController *vc = self.window.rootViewController;
    if ([vc isKindOfClass:CHSplitViewController.class]) {
        [(CHSplitViewController *)vc showDetailViewController:nil];
    }
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    UIViewController *vc = self.window.rootViewController.topViewController;
    if ([vc isKindOfClass:CHSplitViewController.class]) {
        [(CHSplitViewController *)vc showDetailViewController:nil];
        return;
    }
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
    showViewController(viewController, animated, CHRouterShowModePush);
}

- (void)presentSystemViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController.topViewController presentViewController:viewController animated:animated completion:nil];
}

- (void)closeViewController:(UIViewController *)vc animated:(BOOL)animated completion: (void (^ __nullable)(void))completion {
    if (vc.presentedViewController != nil) {
        [vc dismissViewControllerAnimated:animated completion:completion];
    } else {
        UIViewController *rootVC = self.window.rootViewController;
        if ([rootVC isKindOfClass:CHSplitViewController.class]) {
            CHSplitViewController *splitVC = (CHSplitViewController *)rootVC;
            if (splitVC.detailViewController == vc.navigationController || splitVC.detailViewController == vc) {
                [splitVC showDetailViewController:nil];
                if (completion != nil) {
                    dispatch_main_async(completion);
                }
                return;
            }
        }
        UINavigationController *navigationController = vc.navigationController;
        if (navigationController != nil) {
            if (navigationController.navigationBar.items.count <= 1) {
                [navigationController dismissViewControllerAnimated:animated completion:completion];
            } else {
                [navigationController popViewControllerAnimated:animated];
                if (completion != nil) {
                    dispatch_main_async(completion);
                }
            }
        }
    }
}

- (void)showShareItem:(NSArray *)items sender:(id)sender handler:(void (^ __nullable)(BOOL completed, NSError *error))handler {
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    vc.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *error) {
        if (handler != nil) {
            handler(completed, error);
        }
    };
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if ([sender isKindOfClass:UIBarButtonItem.class]) {
            vc.popoverPresentationController.barButtonItem = sender;
        } else if ([sender isKindOfClass:UIView.class]) {
            vc.popoverPresentationController.sourceView = sender;
        } else {
            // TODO: Fix pop share view.
            return;
        }
    }
    [self presentSystemViewController:vc animated:YES];
}

- (void)showAlertWithTitle:(NSString *)title action:(NSString *)action handler:(void (^ __nullable)(void))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel".localized style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    if (action.length <= 0) action = @"OK".localized;
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:action style:UIAlertActionStyleDestructive
                   handler:^(UIAlertAction * action) {
        if (handler != nil) {
            handler();
        }
    }];
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
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
        UIViewController *vc = setRootViewController(self.window, (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad ? CHSplitViewController.class : CHTabBarViewController.class));
        if ([vc conformsToProtocol:@protocol(CHMainViewController)]) {
            [(id<CHMainViewController>)vc viewReset];
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
                    res = showViewController(vc, YES, parseShowMode([parameters valueForKey:@"show"]));
                }
            }
        }
        return res;
    }];
    [routes addRoute:@"/action/openurl" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        id u = [parameters valueForKey:@"url"];
        if (u != nil) {
            NSURL *url = nil;
            if ([u isKindOfClass:NSURL.class]) {
                url = u;
            } else if ([u isKindOfClass:NSString.class] && [u length] > 0) {
                url = [NSURL URLWithString:u];
            }
            res = openURL(url);
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
                res = showViewController(mailVC, YES, CHRouterShowModePresent);
            }
        }
        return res;
    }];
    // chanify router
    JLRoutes *chanify = [JLRoutes routesForScheme:@"chanify"];
    [chanify addRoute:@"node" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSString *endpoint = [parameters valueForKey:@"endpoint"];
        if (endpoint.length > 0) {
            res = [JLRoutes routeURL:[NSURL URLWithString:@"/page/node"] withParameters:@{ @"endpoint": endpoint, @"show": @"present" }];
        }
        return res;
    }];
    [chanify addRoute:@"/action/token/default" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        [CHPasteboard.shared copyWithName:@"Token".localized value:[CHToken.defaultToken formatString:nil direct:YES]];
        return YES;
    }];
    // unmatched router
    routes.unmatchedURLHandler = ^(JLRoutes *routes, NSURL *url, NSDictionary<NSString *, id> *parameters) {
        NSString *scheme = url.scheme;
        if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
            if (showViewController([[CHWebViewController alloc] initWithUrl:url parameters:parameters], YES, parseShowMode([parameters valueForKey:@"show"]))) {
                return;
            }
        }
        openURL(url);
    };
}

static inline BOOL openURL(NSURL *url) {
    BOOL res = NO;
    if (url != nil) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [CHRouter.shared makeToast:@"Can't open url".localized];
            }
        }];
        res = YES;
    }
    return res;
}

static inline CHRouterShowMode parseShowMode(NSString *show) {
    CHRouterShowMode mode = CHRouterShowModePush;
    if (show.length > 0) {
        if ([show isEqualToString:@"present"]) {
            mode = CHRouterShowModePresent;
        } else if ([show isEqualToString:@"detail"]) {
            mode = CHRouterShowModeDetail;
        }
    }
    return mode;
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

static inline BOOL showViewController(UIViewController *vc, BOOL animated, CHRouterShowMode showMode) {
    return showViewControllerToVC(vc, CHRouter.shared.window.rootViewController, animated, showMode);
}

static inline BOOL showViewControllerToVC(UIViewController *vc, UIViewController *rootViewController, BOOL animated, CHRouterShowMode showMode) {
    UIViewController *topViewController = rootViewController.topViewController;
    if (showMode == CHRouterShowModeDetail) {
        if ([rootViewController isKindOfClass:CHSplitViewController.class]) {
            if ([(CHSplitViewController *)rootViewController showDetailViewController:vc]) {
                return YES;
            }
        }
    }
    if (showMode != CHRouterShowModePresent) {
        BOOL hiddenBottomBar = NO;
        if ([topViewController isKindOfClass:UITabBarController.class]) {
            topViewController = ((UITabBarController *)topViewController).selectedViewController;
            hiddenBottomBar = YES;
        }
        UINavigationController *navigationController = nil;
        if ([topViewController isKindOfClass:CHSplitViewController.class]) {
            CHSplitViewController *splitVC = (CHSplitViewController *)topViewController;
            if (splitVC.detailViewController != nil) {
                navigationController = splitVC.detailViewController;
            } else {
                [splitVC showDetailViewController:vc];
                return YES;
            }
        }
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
    if ([rootViewController isKindOfClass:CHSplitViewController.class]) {
        CHSplitViewController *splitVC = (CHSplitViewController *)rootViewController;
        if (checkNavViewController(splitVC.detailViewController, clz)) {
            return YES;
        }
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
        if (checkNavViewController(nav, clz)) {
            return YES;
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

static inline BOOL checkNavViewController(UINavigationController *nav, Class clz) {
    if (nav != nil) {
        for (UIViewController *vc in nav.viewControllers) {
            if ([vc isKindOfClass:clz]) {
                [nav popToViewController:vc animated:NO];
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
            CHIndicatorPanelView *alertView = alert;
            [alert stopAnimating:^{
                [alertView removeFromSuperview];
            }];
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
    toast.font = CHTheme.shared.mediumFont;
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
