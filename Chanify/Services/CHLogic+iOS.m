//
//  CHLogic+iOS.m
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic+iOS.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHNotification.h"
#import "CHWebObjectManager.h"
#import "CHWebFileManager.h"
#import "CHLinkMetaManager.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate>

@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *readChannels;
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
        _readChannels = [NSMutableSet new];
        _webImageManager = nil;
        _webFileManager = nil;
        _linkMetaManager = nil;
        if (!WCSession.isSupported) {
            _watchSession = nil;
        } else {
            _watchSession = WCSession.defaultSession;
            self.watchSession.delegate = self;
            [self.watchSession activateSession];
        }
    }
    return self;
}

- (void)launch {
    [CHNotification.shared checkAuth];
    [self reloadUserDB];
    if (self.userDataSource.srvkey.length > 0) {
        if ([self.nsDataSource keyForUID:self.me.uid].length <= 0) {
            [self.nsDataSource updateKey:self.userDataSource.srvkey uid:self.me.uid];
        }
    } else {
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self bindAccount:nil completion:nil];
        });
    }
}

- (void)active {
    [CHNotification.shared updateStatus];
    [super active];
    [self reloadBadge];
}

- (void)deactive {
    [self reloadBadge];
    [super deactive];
}

#pragma mark - API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion {
    [self bindAccount:[CHSecKey new] completion:completion];
}

#pragma mark - Read & Unread
- (NSInteger)unreadSumAllChannel {
    return [self.userDataSource unreadSumAllChannel];
}

- (NSInteger)unreadWithChannel:(nullable NSString *)cid {
    return [self.userDataSource unreadWithChannel:cid];
}

- (void)addReadChannel:(nullable NSString *)cid {
    if (cid == nil) cid = @"";
    if (![self.readChannels containsObject:cid]) {
        [self.readChannels addObject:cid];
        [self clearUnreadWithChannel:cid];
    }
}

- (void)removeReadChannel:(nullable NSString *)cid {
    if (cid == nil) cid = @"";
    if ([self.readChannels containsObject:cid]) {
        [self.readChannels removeObject:cid];
        [self clearUnreadWithChannel:cid];
    }
}

#pragma mark - Watch
- (BOOL)hasWatch {
    return (self.watchSession != nil && self.watchSession.isPaired);
}

- (BOOL)isWatchAppInstalled {
    BOOL res = (self.hasWatch && self.watchSession.isWatchAppInstalled);
    return res;
}

- (BOOL)syncDataToWatch:(BOOL)focus {
    BOOL res = NO;
    if (self.hasWatch) {
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
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
}

- (void)sessionDidDeactivate:(WCSession *)session {
}

#pragma mark - Subclass methods
- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [super doLogin:user key:key];
    [CHNotification.shared checkAuth];
    // TODO: wait seckey sync to Apple Watch
    [self syncDataToWatch:YES];
}

- (void)doLogout {
    [super doLogout];
    [self updateBadge:0];
    [self syncDataToWatch:YES];
}

- (void)reloadDB:(NSURL *)dbpath uid:(nullable NSString *)uid {
    [super reloadDB:dbpath uid:uid];
    if (self.webImageManager != nil && ![self.webImageManager.uid isEqualToString:uid]) {
        [self.webImageManager close];
        _webImageManager = nil;
    }
    if (self.webFileManager != nil && ![self.webFileManager.uid isEqualToString:uid]) {
        [self.webFileManager close];
        _webFileManager = nil;
    }
    if (self.linkMetaManager != nil && ![self.linkMetaManager.uid isEqualToString:uid]) {
        [self.linkMetaManager close];
        _linkMetaManager = nil;
    }
    if (uid.length > 0) {
        NSURL *basePath = [dbpath.URLByDeletingLastPathComponent URLByAppendingPathComponent:@kCHWebBasePath];
        if (_webImageManager == nil) {
            _webImageManager = [CHWebObjectManager webObjectManagerWithURL:[basePath URLByAppendingPathComponent:@"images"] decoder:[CHWebImageDecoder new]];
            self.webImageManager.uid = uid;
        }
        if (_webFileManager == nil) {
            _webFileManager = [CHWebFileManager webFileManagerWithURL:[basePath URLByAppendingPathComponent:@"files"]];
            self.webFileManager.uid = uid;
        }
        if (_linkMetaManager == nil) {
            _linkMetaManager = [CHLinkMetaManager linkManagerWithURL:[basePath URLByAppendingPathComponent:@"links"]];
            self.linkMetaManager.uid = uid;
        }
    }
}

- (BOOL)isReadChannel:(NSString *)cid {
    return [self.readChannels containsObject:cid];
}

#pragma mark - Private Methods
- (NSData *)watchSyncedData {
    CHTPWatchConfig *cfg = [CHTPWatchConfig new];
    CHUserModel *me = self.me;
    if (me != nil) {
        cfg.userKey = me.key.seckey;
    }
    return cfg.data;
}

- (void)reloadBadge {
    NSInteger badge = 0;
    if (self.userDataSource != nil) {
        for (NSString *cid in self.readChannels) {
            [self clearUnreadWithChannel:cid];
        }
        badge = [self.userDataSource unreadSumAllChannel];
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


@end
