//
//  CHNotification.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHNotification.h"
#import <UserNotifications/UserNotifications.h>
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHDevice.h"

@interface CHNotification () <UNUserNotificationCenterDelegate>

@property (nonatomic, readonly, strong) UNUserNotificationCenter *center;

@end

@implementation CHNotification

+ (instancetype)shared {
    static CHNotification *notification;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [CHNotification new];
    });
    return notification;
}

- (instancetype)init {
    if (self = [super init]) {
        _enabled = NO;
        _pushToken = [NSData new];
        _center = UNUserNotificationCenter.currentNotificationCenter;
        self.center.delegate = self;
        NSMutableSet<UNNotificationCategory *> *categories = [NSMutableSet new];
        if (CHDevice.shared.type == CHDeviceTypeIOS) {
            // General
            [categories addObject:[UNNotificationCategory categoryWithIdentifier:@"general" actions:@[] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction]];
            // Text
            [categories addObject:[UNNotificationCategory categoryWithIdentifier:@"text" actions:@[
                [UNNotificationAction actionWithIdentifier:@"copy" title:@"Copy".localized options:UNNotificationActionOptionForeground],
            ] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction]];
            // Link
            [categories addObject:[UNNotificationCategory categoryWithIdentifier:@"link" actions:@[
                [UNNotificationAction actionWithIdentifier:@"open-link" title:@"Open Link".localized options:UNNotificationActionOptionForeground],
                [UNNotificationAction actionWithIdentifier:@"copy" title:@"Copy".localized options:UNNotificationActionOptionForeground],
            ] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction]];
        }
        [self.center setNotificationCategories: categories];
    }
    return self;
}

- (void)checkAuth {
    @weakify(self);
    UNAuthorizationOptions options = UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert;
    [self.center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError *error) {
        if (error == nil && granted) {
            @strongify(self);
            [self.delegate registerForRemoteNotifications];
        }
    }];
}

- (void)updateStatus {
    @weakify(self);
    [self.center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        BOOL status = (settings.authorizationStatus == UNAuthorizationStatusAuthorized);
        dispatch_main_async(^{
            @strongify(self);
            self.enabled = status;
        });
    }];
    [self.center removeAllDeliveredNotifications];
}

- (void)updateDeviceToken:(NSData *)deviceToken {
    _pushToken = deviceToken ?: [NSData new];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
}

#pragma mark - UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    [self.delegate receiveNotification:notification];
    completionHandler(0);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    [self.delegate receiveNotificationResponse:response];
    completionHandler();
}

#pragma mark - Private Methods
- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [self sendNotifyWithSelector:@selector(notificationStatusChanged)];
    }
}


@end
