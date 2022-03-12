//
//  CHLogic+iOS.m
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic+iOS.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <UserNotifications/UserNotifications.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CHReachability.h"
#import "CHNSDataSource.h"
#import "CHUserDataSource.h"
#import "CHTimelineDataSource.h"
#import "CHMessageModel.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHNotification+Badge.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHWidget.h"
#import "CHToken.h"
#import "CHMock.h"
#import "CHTP.pbobjc.h"

#define kCHDataDownloadModeKey  "data.downloadmode"

@interface CHLogic () <WCSessionDelegate, CHNotificationMessageDelegate>

@property (nonatomic, readonly, strong) CHReachability *reachability;
@property (nonatomic, readonly, strong) CHTimelineDataSource *timelineDataSource;
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
    if (self = [super initWithAppGroup:@kCHAppGroupName]) {
        _reachability = [CHReachability reachabilityForInternetConnection];
        _downloadMode = [NSUserDefaults.standardUserDefaults integerForKey:@kCHDataDownloadModeKey];
        _soundManager = [CHSoundManager soundManagerWithGroupId:@kCHAppGroupName];
        _timelineDataSource = [CHTimelineDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:@kCHAppTimelineGroupName path:@kCHDBTimelineName]];

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

- (void)close {
    [super close];
    [self.timelineDataSource close];
}

- (void)active {
    [super active];
    [self updatePushMessage:NO];
    [self reloadBadge];
    [self.reachability startNotifier];
}

- (void)deactive {
    [self.reachability stopNotifier];
    [CHWidget.shared reloadIfNeeded];
    [self.timelineDataSource flush];
    [self reloadBadge];
    [super deactive];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
    [self recivePushMessage:userInfo];
}

- (BOOL)recivePushMessage:(NSDictionary *)userInfo {
    // TODO: Remove this update call.
    [self updatePushMessage:YES];

    BOOL res = NO;
    NSData *data = nil;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:userInfo mid:&mid data:&data];
    if (uid.length > 0 && [uid isEqualToString:self.me.uid] && mid.length > 0 && data.length > 0) {
        CHUpsertMessageFlags flags = 0;
        CHMessageModel *model = [self.userDataSource upsertMessageData:data nsDB:self.nsDataSource uid:uid mid:mid checker:^BOOL(NSString * _Nonnull cid) {
            return ![self isReadChannel:cid];
        } flags:&flags];
        if (model != nil) {
            if (flags & CHUpsertMessageFlagChannel) {
                [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:model.channel.base64];
            }
            [self sendNotifyWithSelector:@selector(logicMessagesUpdated:) withObject:@[mid]];
            if (flags & CHUpsertMessageFlagUnread) {
                // TODO: Fix calc unread count
                [self sendNotifyWithSelector:@selector(logicMessagesUnreadChanged:) withObject:@(self.userDataSource.unreadSumAllChannel)];
            }
            [self.timelineDataSource upsertUid:uid from:model.from model:model.timeline];
            res = YES;
        }
    }
    return res;
}

- (void)setDownloadMode:(CHLogicDownloadMode)downloadMode {
    if (_downloadMode != downloadMode) {
        _downloadMode = downloadMode;
        [NSUserDefaults.standardUserDefaults setInteger:downloadMode forKey:@kCHDataDownloadModeKey];
    }
}

- (BOOL)isAutoDownload {
    switch (_downloadMode) {
        case CHLogicDownloadModeAuto:
            return YES;
        case CHLogicDownloadModeManual:
            return NO;
        case CHLogicDownloadModeWifiOnly:
            return self.reachability.currentReachabilityStatus == CHNetworkStatusWiFi;
    }
}

- (NSString *)defaultNotificationSound {
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        return [self.nsDataSource notificationSoundForUID:uid];
    }
    return @"";
}

- (void)setDefaultNotificationSound:(NSString *)defaultNotificationSound {
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        [self.nsDataSource updateNotificationSound:defaultNotificationSound uid:uid];
        [self sendNotifyWithSelector:@selector(logicNotificationSoundChanged)];
    }
}

#pragma mark - API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion {
    [self bindAccount:[CHSecKey new] completion:completion];
}

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [super doLogin:user key:key];
    [self updatePushMessage:NO];
    // TODO: wait seckey sync to Apple Watch
    [self syncDataToWatch:NO];
}

- (void)doLogout {
    [super doLogout];
    [self.timelineDataSource close];
    [self updateBadge:0];
    [self syncDataToWatch:NO];
}

#pragma mark - Nodes
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion {
    if (nid.length > 0) {
        CHNodeModel *node = [self.userDataSource nodeWithNID:nid];
        if (node.isStoreDevice) {
            [self updatePushToken:CHNotification.shared.pushToken node:node completion:completion];
            return;
        }
    }
    call_completion(completion, CHLCodeFailed);
}

#pragma mark - Watch
- (BOOL)hasWatch {
    return (self.watchSession != nil && self.watchSession.activationState == WCSessionActivationStateActivated && self.watchSession.isPaired);
}

- (BOOL)isWatchAppInstalled {
    return (self.hasWatch && self.watchSession.isWatchAppInstalled);
}

- (BOOL)syncDataToWatch:(BOOL)focus {
    BOOL res = NO;
    if (self.isWatchAppInstalled) {
        res = [self.watchSession updateApplicationContext:@{
            @"last": @(focus ? NSDate.date.timeIntervalSince1970 : 0),
            @"data": self.watchSyncedData,
        } error:nil];
    }
    return res;
}

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
}

- (void)sessionWatchStateDidChange:(WCSession *)session {
    [self sendNotifyWithSelector:@selector(logicWatchStatusChanged)];
    if (self.isWatchAppInstalled) {
        [self syncDataToWatch:NO];
    }
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
}

- (void)sessionDidDeactivate:(WCSession *)session {
}

#pragma mark - CHNotificationMessageDelegate
- (void)registerForRemoteNotifications {
    dispatch_main_async(^{
        [UIApplication.sharedApplication registerForRemoteNotifications];
    });
}

- (void)receiveNotification:(UNNotification *)notification {
    [self recivePushMessage:try_mock_notification(notification.request.content.userInfo)];
}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {
    NSString *mid = nil;
    NSDictionary *info = try_mock_notification(response.notification.request.content.userInfo);
    NSString *uid = [CHMessageModel parsePacket:info mid:&mid data:nil];
    if (uid.length > 0 && mid.length > 0) {
        CHLogI("Launch with message %u", mid);
        [self recivePushMessage:info];
        CHMessageModel *model = [self.userDataSource messageWithMID:mid];
        if (model.channel.length > 0) {
            NSString *cid = model.channel.base64;
            dispatch_main_async(^{
                [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": cid, @"singleton": @YES, @"show": @"detail" }];
            });
        }
    }
}

#pragma mark - Channel Methods
- (BOOL)insertChannel:(CHChannelModel *)model {
    BOOL res = [super insertChannel:model];
    if (res) {
        [CHWidget.shared upsertChannel:model];
    }
    return res;
}

- (BOOL)updateChannel:(CHChannelModel *)model {
    BOOL res = [super updateChannel:model];
    if (res) {
        [CHWidget.shared upsertChannel:model];
    }
    return res;
}

- (BOOL)deleteChannel:(nullable NSString *)cid {
    BOOL res = [super deleteChannel:cid];
    if (res) {
        [CHWidget.shared deleteChannel:cid];
    }
    return res;
}

#pragma mark - Subclass Methods
- (void)reloadUserDB:(BOOL)force {
    [super reloadUserDB:force];
    [CHWidget.shared reloadDB:self.me.uid];
}

- (void)sendBlockTokenChanged {
    [super sendBlockTokenChanged];
    [self syncDataToWatch:NO];
}

#pragma mark - Private Methods
- (void)updatePushMessage:(BOOL)alert {
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        __block BOOL unreadChanged = NO;
        __block BOOL needAlertUnread= NO;
        NSMutableSet<NSString *> *cids = [NSMutableSet new];
        NSMutableArray<NSString *> *mids = [NSMutableArray new];
        [self.nsDataSource enumerateMessagesWithUID:uid block:^(FMDatabase *db, NSString *mid, NSData *data) {
            CHUpsertMessageFlags flags = 0;
            CHMessageModel *model = [self.userDataSource upsertMessageData:data nsDB:[CHTempNSDatasource datasourceFromDB:db] uid:uid mid:mid checker:^BOOL(NSString * _Nonnull cid) {
                return ![self isReadChannel:cid];
            } flags:&flags];
            if (model != nil) {
                if (flags & CHUpsertMessageFlagChannel) {
                    [cids addObject:model.channel.base64];
                }
                if (flags & CHUpsertMessageFlagUnread) {
                    unreadChanged = YES;
                    if ([model.sound boolValue] > 0) {
                        needAlertUnread = YES;
                    }
                }
                [self.timelineDataSource upsertUid:uid from:model.from model:model.timeline];
            }
            if (mid.length > 0) {
                [mids addObject:mid];
            }
        }];
        if (mids.count > 0) {
            [self.nsDataSource removeMessages:mids uid:uid];
            [self sendNotifyWithSelector:@selector(logicMessagesUpdated:) withObject:mids];
        }
        [self.nsDataSource flush];
        if (cids.count > 0) {
            [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:cids.allObjects];
        }
        if (unreadChanged) {
            // TODO: Fix calc unread count
            [self sendNotifyWithSelector:@selector(logicMessagesUnreadChanged:) withObject:@(self.userDataSource.unreadSumAllChannel)];
        }
        if (alert && needAlertUnread) {
            [self sendAlertNewMessage];
        }
    }
}

- (NSData *)watchSyncedData {
    CHTPWatchConfig *cfg = [CHTPWatchConfig new];
    CHUserModel *me = self.me;
    if (me != nil) {
        cfg.userKey = me.key.seckey;
        for (CHNodeModel *node in self.userDataSource.loadNodes) {
            if (node.isSupportWatch && !node.isSystem) {
                CHTPNode *n = [CHTPNode new];
                n.nid = node.nid;
                n.flags = node.flags;
                n.name = node.name;
                n.version = node.version;
                n.endpoint = node.endpoint;
                n.icon = node.icon;
                n.pubkey = node.pubkey;
                [cfg.nodesArray addObject:n];
            }
        }
        for (NSString *token in self.blockedTokens) {
            CHToken *tk = [CHToken tokenWithString:token];
            if (!tk.isExpired) {
                CHTPBlockItem *item = [CHTPBlockItem new];
                item.token = token;
                [cfg.blocklistArray addObject:item];
            }
        }
    }
    return cfg.data;
}

- (void)reloadBadge {
    NSInteger badge = 0;
    if (self.userDataSource != nil) {
        NSMutableArray<NSString *> *cids = [NSMutableArray new];
        for (NSString *cid in self.readChannelIDs) {
            if ([self.userDataSource clearUnreadWithChannel:cid]) {
                [cids addObject:cid];
            }
        }
        badge = [self.userDataSource unreadSumAllChannel];
        if (cids.count > 0) {
            [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:cids];
            [self sendNotifyWithSelector:@selector(logicMessagesUnreadChanged:) withObject:@(badge)];
        }
    }
    [self updateBadge:badge];
}

- (void)updateBadge:(NSInteger)badge {
    CHNotification.shared.notificationBadge = badge;
    [self.nsDataSource updateBadge:badge uid:self.me.uid];
}

- (BOOL)clearUnreadWithChannel:(nullable NSString *)cid {
    BOOL res = [self.userDataSource clearUnreadWithChannel:cid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:cid];
        // TODO: Fix calc unread count
        [self sendNotifyWithSelector:@selector(logicMessagesUnreadChanged:) withObject:@(self.userDataSource.unreadSumAllChannel)];
    }
    return res;
}

- (void)sendAlertNewMessage {
    dispatch_main_async(^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            AudioServicesPlaySystemSound(1007);
        }
    });
}

static inline void call_completion(CHLogicBlock completion, CHLCode result) {
    if (completion != nil) {
        dispatch_main_async(^{
            completion(result);
        });
    }
}


@end
