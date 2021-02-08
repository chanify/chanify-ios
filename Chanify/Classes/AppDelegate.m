//
//  AppDelegate.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "AppDelegate.h"
#import "CHRouter.h"
#import "CHNotification.h"

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

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [CHRouter.shared active];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [CHRouter.shared deactive];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CHNotification.shared updateDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [CHNotification.shared receiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}


@end
