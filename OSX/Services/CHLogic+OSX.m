//
//  CHLogic+OSX.m
//  OSX
//
//  Created by WizJin on 2021/5/2.
//

#import "CHLogic+OSX.h"
#import <AppKit/AppKit.h>
#import <UserNotifications/UserNotifications.h>
#import "CHNotification.h"

@interface CHLogic () <CHNotificationMessageDelegate>

@end

@implementation CHLogic

+ (instancetype)shared {
    static CHLogic *logic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logic = [CHLogic new];
    });
    return logic;
}

- (instancetype)init {
    if (self = [super initWithAppGroup:@kCHAppOSXGroupName]) {
        CHNotification.shared.delegate = self;
    }
    return self;
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
    if (userInfo != nil) {
        
        
        
    }
}

#pragma mark - CHNotificationMessageDelegate
- (void)registerForRemoteNotifications {
    dispatch_main_async(^{
        [NSApplication.sharedApplication registerForRemoteNotifications];
    });
}

- (void)receiveNotification:(UNNotification *)notification {
    [self receiveRemoteNotification:notification.request.content.userInfo];
}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {
    [self receiveRemoteNotification:response.notification.request.content.userInfo];
}


@end
