//
//  CHNotification.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHNotificationDelegate <NSObject>

- (void)notificationStatusChanged;

@end

@interface CHNotification : CHManager<id<CHNotificationDelegate>>

@property (nonatomic, readonly, assign) BOOL enabled;
@property (nonatomic, assign) NSUInteger notificationBadge;

+ (instancetype)shared;
- (void)checkAuth;
- (void)updateStatus;
- (void)updateDeviceToken:(NSData *)deviceToken;
- (void)receiveRemoteNotification:(NSDictionary *)userInfo;


@end

NS_ASSUME_NONNULL_END
