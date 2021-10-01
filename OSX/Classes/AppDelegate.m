//
//  AppDelegate.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "AppDelegate.h"
#import "CHRouter.h"
#import "CHLogic.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [CHRouter.shared launch];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [CHRouter.shared close];
}

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CHLogic.shared updatePushToken:deviceToken];
}

- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *, id> *)userInfo {
    [CHLogic.shared receiveRemoteNotification:userInfo];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    return [CHRouter.shared handleReopen:sender hasVisibleWindows:flag];
}


@end
