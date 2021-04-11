//
//  NotificationViewController.m
//  NotificationContent
//
//  Created by WizJin on 2021/4/11.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - UNNotificationContentExtension
- (void)didReceiveNotification:(UNNotification *)notification {

}

- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption option))completion {
    completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
}


@end
