//
//  NotificationViewController.m
//  NotificationContent
//
//  Created by WizJin on 2021/4/11.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "CHIconView.h"
#import "CHActionGroup.h"
#import "NSString+CHLocalized.h"
#import "CHUtils.h"
#import "CHConfig.h"
#import "CHTheme.h"

@interface NotificationViewController () <UNNotificationContentExtension, CHActionGroupDelegate>

@property (nonatomic, readonly, strong) UILabel *toastLabel;
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *bodyLabel;
@property (nonatomic, readonly, strong) CHActionGroup *actionGroup;
@property (nonatomic, readonly, strong) NSLayoutConstraint *toastConstraint;
@property (nonatomic, readonly, strong) NSLayoutConstraint *actionConstraint;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;

    UILabel *toastLabel = [UILabel new];
    [self.view addSubview:(_toastLabel = toastLabel)];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.backgroundColor = UIColor.secondarySystemBackgroundColor;
    toastLabel.textColor = theme.labelColor;
    toastLabel.font = [UIFont systemFontOfSize:16];
    toastLabel.numberOfLines = 1;
    toastLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _toastConstraint = [toastLabel.heightAnchor constraintEqualToConstant:0];
    NSLayoutConstraint *toastTopConstraint = [toastLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor];
    [self.view addConstraints:@[
        toastTopConstraint,
        [toastLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [toastLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        self.toastConstraint,
    ]];

    UILabel *titleLabel = [UILabel new];
    [self.view addSubview:(_titleLabel = titleLabel)];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = theme.labelColor;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.numberOfLines = 1;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *titleLeftConstraint = [titleLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16];
    [self.view addConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:toastLabel.bottomAnchor],
        [titleLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
        titleLeftConstraint,
    ]];

    UILabel *bodyLabel = [UILabel new];
    [self.view addSubview:(_bodyLabel = bodyLabel)];
    bodyLabel.textAlignment = NSTextAlignmentLeft;
    bodyLabel.textColor = theme.labelColor;
    bodyLabel.font = [UIFont systemFontOfSize:16];
    bodyLabel.numberOfLines = 10;
    bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
        [bodyLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor],
        [bodyLabel.leftAnchor constraintEqualToAnchor:titleLabel.leftAnchor],
        [bodyLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
    ]];

    CHActionGroup *actionGroup = [CHActionGroup new];
    [self.view addSubview:(_actionGroup = actionGroup)];
    actionGroup.translatesAutoresizingMaskIntoConstraints = NO;
    actionGroup.lineWidth = 1.0;
    actionGroup.delegate = self;
    _actionConstraint = [actionGroup.heightAnchor constraintEqualToConstant:0];
    self.actionConstraint.priority = UILayoutPriorityDefaultHigh;
    [self.view addConstraints:@[
        [actionGroup.topAnchor constraintEqualToAnchor:bodyLabel.bottomAnchor constant:12],
        [actionGroup.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [actionGroup.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [actionGroup.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        self.actionConstraint,
    ]];

    if (@available(iOS 15, *)) {
        toastTopConstraint.constant = 12;
        titleLeftConstraint.constant += 40;

        CHIconView *iconView = [CHIconView new];
        [self.view addSubview:iconView];
        iconView.image = @"";
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:@[
            [iconView.topAnchor constraintEqualToAnchor:titleLabel.topAnchor],
            [iconView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:8],
            [iconView.widthAnchor constraintEqualToConstant:38],
            [iconView.heightAnchor constraintEqualToAnchor:iconView.widthAnchor],
        ]];
    }
}

#pragma mark - UNNotificationContentExtension
- (void)didReceiveNotification:(UNNotification *)notification {
    UNNotificationContent *content = notification.request.content;
    self.titleLabel.text = content.title ?: @"";
    self.bodyLabel.text = content.body ?: @"";

    NSMutableArray<CHActionItemModel *> *actions = [NSMutableArray new];
    NSDictionary *info = content.userInfo;
    if (info.count > 0) {
        id autoCopy = [info valueForKey:@"autocopy"];
        if (autoCopy != nil && [autoCopy boolValue]) {
            [self doCopy:info];
        }
        for (NSDictionary *item in [info valueForKey:@"actions"]) {
            CHActionItemModel *model = [CHActionItemModel actionItemWithDictionary:item];
            if (model != nil) {
                [actions addObject:model];
            }
        }
    }
    self.title = [info valueForKey:@"title"] ?: @"Chanify";
    if (@available(iOS 15, *)) {
        if (self.titleLabel.text.length <= 0) {
            self.titleLabel.text = self.title;
        }
    }
    self.actionGroup.actions = actions;
    self.actionConstraint.constant = (actions.count > 0 ? CHActionGroup.defaultHeight : 0);
    [self.view setNeedsLayout];
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

#pragma mark - CHActionGroupDelegate
- (void)actionGroupSelected:(nullable CHActionItemModel *)item {
    NSURL *link = item.link;
    if (link != nil) {
        [self.extensionContext openURL:link completionHandler:nil];
    }
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
