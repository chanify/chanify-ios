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
#import "CHNotification.h"
#import "CHNodeModel.h"
#import "CHDevice.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate, CHNotificationMessageDelegate>

@property (nonatomic, readonly, strong) NSMutableArray<CHNodeModel *> *nodes;
@property (nonatomic, readonly, strong) WCSession *watchSession;

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
        _nodes = [NSMutableArray new];
        if (!WCSession.isSupported) {
            _watchSession = nil;
        } else {
            _watchSession = WCSession.defaultSession;
            self.watchSession.delegate = self;
        }
        CHNotification.shared.delegate = self;
    }
    return self;
}

- (void)launch {
    [super launch];
    [self.watchSession activateSession];
}

- (void)active {
    [super active];
}

- (void)deactive {
    [super deactive];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
}

- (void)updatePushToken:(NSData *)pushToken {
    [super updatePushToken:pushToken];
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

#pragma mark - CHNotificationMessageDelegate
- (void)registerForRemoteNotifications {
    dispatch_main_async(^{
        [WKExtension.sharedExtension registerForRemoteNotifications];
    });
}

- (void)receiveNotification:(UNNotification *)notification {
}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {
}

#pragma mark - Private Methods
- (void)updateContext:(WCSession *)session {
    NSData *data = [session.receivedApplicationContext objectForKey:@"data"];
    NSError *error = nil;
    CHUserModel *me = nil;
    CHTPWatchConfig *cfg = [CHTPWatchConfig parseFromData:data ?: [NSData new] error:&error];
    if (error == nil) {
        me = [CHUserModel modelWithKey:[CHSecKey secKeyWithData:cfg.userKey]];
    }
    BOOL updated = NO;
    if (self.me == nil || ![self.me.uid isEqualToString:me.uid]) {
        [self updateUserModel:me];
        [self reloadUserDB:NO];
        updated = YES;
    }
    if (self.me != nil) {
        NSMutableArray<CHNodeModel *> *nodes = [NSMutableArray new];
        for (CHTPNode *node in self.nodes) {
            CHNodeModel *n = [CHNodeModel modelWithNID:node.nid name:node.name version:node.version endpoint:node.endpoint pubkey:node.pubkey flags:(CHNodeModelFlags)(node.flags) features:@""];
            n.icon = node.icon;
            [nodes addObject:n];
        }
        if (![nodes isEqualToArray:self.nodes]) {
            _nodes = nodes;
            updated = YES;
        }
    }
    if (updated) {
        [self sendNotifyWithSelector:@selector(logicUserInfoChanged:) withObject:me];
    }
}


@end
