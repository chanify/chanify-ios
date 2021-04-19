//
//  CHNotification.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHNotification.h"
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIApplication.h>
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHLogic.h"
#import "CHRouter.h"
#import "CHMock.h"

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
        _center = UNUserNotificationCenter.currentNotificationCenter;
        self.center.delegate = self;
        NSMutableSet<UNNotificationCategory *> *categories = [NSMutableSet new];
        // General
        [categories addObject:[UNNotificationCategory categoryWithIdentifier:@"text" actions:@[
            [UNNotificationAction actionWithIdentifier:@"copy" title:@"Copy".localized options:UNNotificationActionOptionForeground],
        ] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction]];
        // Link
        [categories addObject:[UNNotificationCategory categoryWithIdentifier:@"link" actions:@[
            [UNNotificationAction actionWithIdentifier:@"open-link" title:@"Open Link".localized options:UNNotificationActionOptionForeground],
            [UNNotificationAction actionWithIdentifier:@"copy" title:@"Copy".localized options:UNNotificationActionOptionForeground],
        ] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction]];
        [self.center setNotificationCategories: categories];
    }
    return self;
}

- (void)checkAuth {
    UNAuthorizationOptions options = UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert;
    [self.center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError *error) {
        if (error == nil && granted) {
            dispatch_main_async(^{
                [UIApplication.sharedApplication registerForRemoteNotifications];
            });
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

- (NSUInteger)notificationBadge {
    return UIApplication.sharedApplication.applicationIconBadgeNumber;
}

- (void)setNotificationBadge:(NSUInteger)notificationBadge {
    UIApplication.sharedApplication.applicationIconBadgeNumber = notificationBadge;
}

- (void)updateDeviceToken:(NSData *)deviceToken {
    [CHLogic.shared updatePushToken:deviceToken];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
}

#pragma mark - UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    [CHLogic.shared recivePushMessage:try_mock_notification(notification.request.content.userInfo)];
    completionHandler(0);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    NSString *mid = nil;
    NSDictionary *info = try_mock_notification(response.notification.request.content.userInfo);
    NSString *uid = [CHMessageModel parsePacket:info mid:&mid data:nil];
    if (uid.length > 0 && mid.length > 0) {
        CHLogI("Launch with message %ux", mid);
        [CHLogic.shared recivePushMessage:info];
        CHMessageModel *model = [CHLogic.shared.userDataSource messageWithMID:mid];
        if (model.channel.length > 0) {
            NSString *cid = model.channel.base64;
            dispatch_main_async(^{
                [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": cid, @"singleton": @YES, @"show": @"detail" }];
            });
        
        }
    }
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
