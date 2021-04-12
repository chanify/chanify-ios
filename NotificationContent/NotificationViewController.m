//
//  NotificationViewController.m
//  NotificationContent
//
//  Created by WizJin on 2021/4/11.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "NSString+CHLocalized.h"
#import "CHUtils.h"
#import "CHConfig.h"

@interface NotificationViewController () <UNNotificationContentExtension>

@property (nonatomic, readonly, strong) UILabel *toastLabel;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.toastLabel == nil) {
        UILabel *toastLabel = [UILabel new];
        [self.view addSubview:(_toastLabel = toastLabel)];
        toastLabel.textAlignment = NSTextAlignmentCenter;
        toastLabel.backgroundColor = UIColor.secondarySystemBackgroundColor;
        toastLabel.textColor = UIColor.labelColor;
        toastLabel.font = [UIFont systemFontOfSize:16];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.toastLabel.frame = self.view.bounds;
}

#pragma mark - UNNotificationContentExtension
- (void)didReceiveNotification:(UNNotification *)notification {
    NSDictionary *info = notification.request.content.userInfo;
    if (info.count > 0) {
        id autoCopy = [info valueForKey:@"autocopy"];
        if (autoCopy != nil && [autoCopy boolValue]) {
            [self doCopy:info];
        }
    }
}

- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption option))completion {
    NSDictionary *info = response.notification.request.content.userInfo;
    if (info.count > 0) {
        NSString *action = response.actionIdentifier;
        if ([action isEqualToString:@"copy"]) {
            [self doCopy:info];
        } else if ([action isEqualToString:@"open-link"]) {
            NSString *url = [info valueForKey:@"link"];
            if (url.length > 0) {
                [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
            }
        }
    }
    completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
}

#pragma mark - Private Methods
- (void)doCopy:(NSDictionary *)info {
    NSString *copy = [info valueForKey:@"copy"];
    if (copy.length <= 0) copy = [info valueForKey:@"link"];
    if (copy.length > 0) {
        UIPasteboard.generalPasteboard.string = copy ?: @"";
        [self showToast:@"Copied".localized];
    }
}

- (void)showToast:(NSString *)msg {
    self.toastLabel.text = msg;
    @weakify(self);
    [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateSlowDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        @strongify(self);
        self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, 30);
    } completion:^(UIViewAnimatingPosition finalPosition) {
        @strongify(self);
        [self hideToast];
    }];
}

- (void)hideToast {
    @weakify(self);
    dispatch_main_after(kCHAnimateSlowDuration*2, ^{
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateSlowDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            @strongify(self);
            self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, 0);
        } completion:nil];
    });
}


@end
