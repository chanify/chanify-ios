//
//  CHNotification.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class UNNotification;
@class UNNotificationResponse;

@protocol CHNotificationDelegate <NSObject>

- (void)notificationStatusChanged;

@end

@protocol CHNotificationMessageDelegate <NSObject>

- (void)registerForRemoteNotifications;
- (void)receiveNotification:(UNNotification *)notification;
- (void)receiveNotificationResponse:(UNNotificationResponse *)response;

@end

@interface CHNotification : CHManager<id<CHNotificationDelegate>>

@property (nonatomic, readonly, assign) BOOL enabled;
@property (nonatomic, readonly, strong) NSData *pushToken;
@property (nonatomic, nullable, weak) id<CHNotificationMessageDelegate> delegate;

+ (instancetype)shared;
- (void)checkAuth;
- (void)updateStatus;
- (void)updateDeviceToken:(NSData *)deviceToken;
- (void)receiveRemoteNotification:(NSDictionary *)userInfo;


@end

NS_ASSUME_NONNULL_END
