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
    NSDictionary *info = response.notification.request.content.userInfo;
    if (info.count > 0) {
        NSString *action = response.actionIdentifier;
        if ([action isEqualToString:@"copy"]) {
            NSString *copy = [info valueForKey:@"copy"];
            if (copy.length <= 0) copy = [info valueForKey:@"link"];
            UIPasteboard.generalPasteboard.string = copy ?: @"";
        } else if ([action isEqualToString:@"open-link"]) {
            NSString *url = [info valueForKey:@"link"];
            if (url.length > 0) {
                [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
            }
        }
    }
    completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
}


@end
