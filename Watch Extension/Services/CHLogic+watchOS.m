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
#import "CHUserDataSource.h"
#import "CHNotification.h"
#import "CHNodeModel.h"
#import "CHDevice.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate, CHNotificationMessageDelegate>

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
    if (self = [super initWithAppGroup:@kCHAppWatchGroupName]) {
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

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
}

- (void)updatePushToken:(NSData *)pushToken {
    [super updatePushToken:pushToken];
}

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [super doLogin:user key:key];
}

- (void)doLogout {
    [super doLogout];
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
        if (self.me != nil) {
            [self logoutWithCompletion:nil];
        }
        
        [self updateUserModel:me];
        [self reloadUserDB:NO];
        
        if (self.me != nil) {
            [self importAccount:self.me.key.seckey.base64 completion:nil];
        }
        updated = YES;
    }
    if (self.me != nil) {
        for (CHTPNode *node in cfg.nodesArray) {
            [self bindNode:node];
        }
        NSMutableSet<NSString *> *blocks = [NSMutableSet new];
        for (CHTPBlockItem *item in cfg.blocklistArray) {
            if (item.token.length > 0) {
                [blocks addObject:item.token];
            }
        }
        NSMutableArray<NSString *> *removedItems = [NSMutableArray new];
        for (NSString *token in self.blockedTokens) {
            if ([blocks containsObject:token]) {
                [blocks removeObject:token];
            } else {
                [removedItems addObject:token];
            }
        }
        if (removedItems.count > 0) {
            [self removeBlockedTokens:removedItems];
        }
        if (blocks.count > 0) {
            for (NSString *token in blocks) {
                [self upsertBlockedToken:token];
            }
        }
    }
    if (updated) {
        [self sendNotifyWithSelector:@selector(logicUserInfoChanged:) withObject:me];
    }
}

- (void)bindNode:(CHTPNode *)node {
    if (node.nid.length > 0 && ![node.nid isEqualToString:@"sys"]) {
        if ([self.userDataSource keyForNodeID:node.nid].length <= 0) {
            @weakify(self);
            [self loadNodeWitEndpoint:node.endpoint completion:^(CHLCode result, NSDictionary *data) {
                if (result == CHLCodeOK) {
                    CHNodeModel *model = [CHNodeModel modelWithNSDictionary:data];
                    if (model != nil) {
                        model.flags = (CHNodeModelFlags)node.flags;
                        model.icon = node.icon;
                        @strongify(self);
                        [self insertNode:model completion:^(CHLCode result) {
                            if (result == CHLCodeOK && model.isStoreDevice) {
                                @strongify(self);
                                [self updatePushToken:CHNotification.shared.pushToken node:[self nodeModelWithNID:model.nid] completion:nil];
                            }
                        }];
                    }
                }
            }];
        }
    }
}


@end
