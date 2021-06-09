//
//  AppDelegate.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "AppDelegate.h"
#import "CHRouter.h"
#import "CHLogic.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return [CHRouter.shared launchWithOptions:launchOptions];
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

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [CHRouter.shared active];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [CHRouter.shared deactive];
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
