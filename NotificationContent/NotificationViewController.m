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
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *bodyLabel;
@property (nonatomic, readonly, strong) NSLayoutConstraint *toastConstraint;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *toastLabel = [UILabel new];
    [self.view addSubview:(_toastLabel = toastLabel)];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.backgroundColor = UIColor.secondarySystemBackgroundColor;
    toastLabel.textColor = UIColor.labelColor;
    toastLabel.font = [UIFont systemFontOfSize:16];
    toastLabel.numberOfLines = 1;
    toastLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _toastConstraint = [toastLabel.heightAnchor constraintEqualToConstant:0];
    [self.view addConstraints:@[
        [toastLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [toastLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [toastLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        self.toastConstraint,
    ]];

    UILabel *titleLabel = [UILabel new];
    [self.view addSubview:(_titleLabel = titleLabel)];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = UIColor.labelColor;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.numberOfLines = 1;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:toastLabel.bottomAnchor],
        [titleLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16],
        [titleLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
    ]];

    UILabel *bodyLabel = [UILabel new];
    [self.view addSubview:(_bodyLabel = bodyLabel)];
    bodyLabel.textAlignment = NSTextAlignmentLeft;
    bodyLabel.textColor = UIColor.labelColor;
    bodyLabel.font = [UIFont systemFontOfSize:16];
    bodyLabel.numberOfLines = 10;
    bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
        [bodyLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor],
        [bodyLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16],
        [bodyLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
        [bodyLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-12],
    ]];
}

#pragma mark - UNNotificationContentExtension
- (void)didReceiveNotification:(UNNotification *)notification {
    UNNotificationContent *content = notification.request.content;
    self.titleLabel.text = content.title ?: @"";
    self.bodyLabel.text = content.body ?: @"";
    [self.view setNeedsLayout];

    NSDictionary *info = content.userInfo;
    if (info.count > 0) {
        id autoCopy = [info valueForKey:@"autocopy"];
        if (autoCopy != nil && [autoCopy boolValue]) {
            [self doCopy:info];
        }
    }
    self.title = [info valueForKey:@"title"] ?: @"CHANIFY";
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
        self.toastConstraint.constant = 30;
        [self.view layoutIfNeeded];
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
            self.toastConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:nil];
    });
}


@end
