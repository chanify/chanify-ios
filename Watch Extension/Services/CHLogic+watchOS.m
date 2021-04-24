//
//  CHLogic+watchOS.m
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic+watchOS.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <UserNotifications/UserNotifications.h>
#import <WatchKit/WatchKit.h>
#import "CHDevice.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic, readonly, strong) WCSession *watchSession;
@property (nonatomic, readonly, strong) UNUserNotificationCenter *center;

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
    if (self = [super init]) {
        _center = UNUserNotificationCenter.currentNotificationCenter;
        self.center.delegate = self;
        
        if (!WCSession.isSupported) {
            _watchSession = nil;
        } else {
            _watchSession = WCSession.defaultSession;
            self.watchSession.delegate = self;
        }
        
        CHLogI("User-agent: %s", CHDevice.shared.userAgent.cstr);
    }
    return self;
}

- (void)launch {
    [self.watchSession activateSession];
    [self checkAuth];
}

- (void)active {
    [super active];
}

- (void)deactive {
    [super deactive];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
    
}

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
    [self updateContext:session];
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        [self updateContext:session];
    });
}

#pragma mark - UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(0);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    completionHandler();
}

#pragma mark - Private Methods
- (void)checkAuth {
    UNAuthorizationOptions options = UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert;
    [self.center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError *error) {
        if (error == nil && granted) {
            dispatch_main_async(^{
                [WKExtension.sharedExtension registerForRemoteNotifications];
            });
        }
    }];
}

- (void)updateContext:(WCSession *)session {
    NSData *data = [session.receivedApplicationContext objectForKey:@"data"];
    NSError *error = nil;
    CHUserModel *me = nil;
    CHTPWatchConfig *cfg = [CHTPWatchConfig parseFromData:data ?: [NSData new] error:&error];
    if (error == nil) {
        me = [CHUserModel modelWithKey:[CHSecKey secKeyWithData:cfg.userKey]];
    }
    if (self.me == nil || ![self.me.uid isEqualToString:me.uid]) {
        [self updateUserModel:me];
        [self sendNotifyWithSelector:@selector(logicUserInfoChanged:) withObject:me];
    }
}


@end
