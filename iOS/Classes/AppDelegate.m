//
//  AppDelegate.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "AppDelegate.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHNotification.h"

// Kept in this compilation unit so the existing iOS target includes the delegate.
@interface CHSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, nullable, strong) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CHLogic.shared launch];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    BOOL res = YES;
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        res = [CHRouter.shared handleURL:userActivity.webpageURL];
    }
    return res;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return [CHRouter.shared handleURL:url];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void(^)(BOOL succeeded))completionHandler {
    BOOL res = [CHRouter.shared handleShortcut:shortcutItem.type];
    if (completionHandler != NULL) {
        completionHandler(res);
    }
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:session.role];
    configuration.delegateClass = CHSceneDelegate.class;
    return configuration;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [CHLogic.shared close];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CHLogic.shared updatePushToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [CHLogic.shared receiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}


@end

@implementation CHSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    [CHRouter.shared connectToWindowScene:(UIWindowScene *)scene];
    self.window = CHRouter.shared.window;
    for (UIOpenURLContext *context in options.URLContexts) {
        [CHRouter.shared handleURL:context.URL];
    }
    for (NSUserActivity *activity in options.userActivities) {
        [self scene:scene continueUserActivity:activity];
    }
    if (options.shortcutItem != nil) {
        [CHRouter.shared handleShortcut:options.shortcutItem.type];
    }
    if (options.notificationResponse != nil) {
        [CHNotification.shared.delegate receiveNotificationResponse:options.notificationResponse];
    }
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [CHRouter.shared active];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    [CHRouter.shared deactive];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)contexts {
    for (UIOpenURLContext *context in contexts) {
        [CHRouter.shared handleURL:context.URL];
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)activity {
    if ([activity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && activity.webpageURL != nil) {
        [CHRouter.shared handleURL:activity.webpageURL];
    }
}

- (void)windowScene:(UIWindowScene *)scene performActionForShortcutItem:(UIApplicationShortcutItem *)item completionHandler:(void (^)(BOOL))completionHandler {
    completionHandler([CHRouter.shared handleShortcut:item.type]);
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if (appDelegate.window == self.window) {
        appDelegate.window = nil;
    }
    self.window = nil;
}

@end
