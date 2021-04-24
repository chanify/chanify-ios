//
//  CHLogic+iOS.m
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic+iOS.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHMessageModel.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHNotification.h"
#import "CHWebObjectManager.h"
#import "CHWebFileManager.h"
#import "CHLinkMetaManager.h"
#import "CHDevice.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate>

@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *readChannels;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *invalidNodes;
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
        _nsDataSource = [CHNSDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:@kCHAppGroupName path:@kCHDBNotificationServiceName]];
        _userDataSource = nil;
        _readChannels = [NSMutableSet new];
        _invalidNodes = [NSMutableSet new];
        _webImageManager = nil;
        _webFileManager = nil;
        _linkMetaManager = nil;
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
    [CHNotification.shared checkAuth];
    [self.watchSession activateSession];
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
    [super active];
    [CHNotification.shared updateStatus];
    [self reloadUserDB];
    [self updatePushMessage:NO];
    [self reloadBadge];
}

- (void)deactive {
    [self reloadBadge];
    [self.nsDataSource close];
    [self.userDataSource close];
    [super deactive];
}

- (void)resetData {
    if (self.userDataSource != nil) {
        [self.userDataSource close];
        [NSFileManager.defaultManager removeItemAtPath:self.userDataSource.dsURL.path error:nil];
        _userDataSource = nil;
        [self reloadUserDB];
    }
}

- (BOOL)recivePushMessage:(NSDictionary *)userInfo {
    // TODO: Remove this update call.
    [self updatePushMessage:YES];

    BOOL res = NO;
    NSData *data = nil;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:userInfo mid:&mid data:&data];
    if (uid.length > 0 && [uid isEqualToString:self.me.uid] && mid.length > 0 && data.length > 0) {
        CHUpsertMessageFlags flags= 0;
        CHMessageModel *model = [self.userDataSource upsertMessageData:data ks:self.nsDataSource uid:uid mid:mid checker:^BOOL(NSString * _Nonnull cid) {
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
            res = YES;
        }
    }
    return res;
}

- (void)updatePushToken:(NSData *)pushToken {
    [super updatePushToken:pushToken];
    if (self.me != nil) {
        [self updatePushToken:pushToken endpoint:self.baseURL node:nil completion:nil retry:YES];
        for (CHNodeModel *node in self.userDataSource.loadNodes) {
            if (node.isStoreDevice) {
                [self updatePushToken:pushToken endpoint:node.apiURL node:node completion:nil retry:NO];
            }
        }
    }
}

#pragma mark - API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion {
    [self bindAccount:[CHSecKey new] completion:completion];
}

- (void)importAccount:(NSString *)key completion:(nullable CHLogicBlock)completion {
    CHSecKey *seckey = [CHSecKey secKeyWithData:[NSData dataFromBase64:key]];
    if (seckey == nil) {
        call_completion(completion, CHLCodeFailed);
    } else {
        @weakify(self);
        [self bindAccount:seckey completion:^(CHLCode result) {
            if (completion != nil) {
                completion(result);
            }
            if (result == CHLCodeOK) {
                @strongify(self);
                [self updateNodeBind];
            }
        }];
    }
}

- (void)bindAccount:(nullable CHSecKey *)key completion:(nullable CHLogicBlock)completion {
    CHDevice *device = CHDevice.shared;
    CHUserModel *user = (key == nil ? self.me : [CHUserModel modelWithKey:key]);
    if (user == nil) {
        call_completion(completion, CHLCodeFailed);
    } else {
        NSDictionary *parameters = @{
            @"device": @{
                    @"uuid": device.uuid.hex,
                    @"key": device.key.pubkey.base64,
                    @"name": device.name,
                    @"model": device.model,
                    @"type": @(device.type),
            },
            @"user": @{
                    @"uid": user.uid,
                    @"key": user.key.pubkey.base64,
            },
        };
        @weakify(self);
        [self sendCmd:@"bind-user" user:user parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            CHLCode ret = CHLCodeFailed;
            if (error != nil) {
                CHLogE("Bind account failed: %s", error.description.cstr);
            } else if ([[result valueForKey:@"res"] integerValue] >= 300) {
                CHLogE("Bind account failed: %d/%s", [[result valueForKey:@"res"] integerValue], [[result valueForKey:@"msg"] cstr]);
            } else {
                CHLogI("Bind account success.");
                @strongify(self);
                if ((self.me == user) // Note: is retry
                    || [user.key saveTo:@kCHUserSecKeyName device:NO]) {
                    [self doLogin:user key:[user.key decode:[NSData dataFromBase64:[result valueForKey:@"key"]]]];
                    ret = CHLCodeOK;
                }
            }
            call_completion(completion, ret);
        }];
    }
}

- (void)logoutWithCompletion:(nullable CHLogicBlock)completion {
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        [self unbindNode:node];
    }
    if (self.me == nil) {
        call_completion(completion, CHLCodeOK);
    } else {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
        };
        @weakify(self);
        [self sendCmd:@"unbind-user" user:self.me parameters:parameters completion:^(NSURLResponse *response,  NSDictionary *result, NSError *error) {
            CHLCode ret = CHLCodeFailed;
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            if (error != nil && resp.statusCode != 404) {
                CHLogE("Unbind account failed:", error.description.cstr);
            } else {
                CHLogI("Unbind account success.");
                @strongify(self);
                [self doLogout];
                ret = CHLCodeOK;
            }
            call_completion(completion, CHLCodeOK);
        }];
    }
}

#pragma mark - Nodes
- (void)updateNodeInfo:(nullable NSString*)nid completion:(nullable CHLogicBlock)completion {
    CHNodeModel *node = [self.userDataSource nodeWithNID:nid];
    if (node != nil && !node.isSystem) {
        @weakify(self);
        [self loadNodeWitEndpoint:node.endpoint completion:^(CHLCode result, NSDictionary *info) {
            CHLCode ret = CHLCodeFailed;
            if (result == CHLCodeOK) {
                NSString *nid = [info valueForKey:@"nodeid"];
                if ([node.nid isEqualToString:nid]) {
                    NSData *pubKey = [NSData dataFromBase64:[info valueForKey:@"pubkey"]];
                    if (pubKey.length > 0 && [CHNodeModel verifyNID:nid pubkey:pubKey]) {
                        BOOL needUpdated = NO;
                        if (![pubKey isEqualToData:node.pubkey]) {
                            node.pubkey = pubKey;
                            needUpdated = YES;
                        }
                        NSString *version = [info valueForKey:@"version"];
                        if (version.length > 0 && ![version isEqualToString:node.version]) {
                            node.version = version;
                            needUpdated = YES;
                        }
                        NSString *endpoint = [info valueForKey:@"endpoint"];
                        if (![node.endpoint isEqualToString:endpoint]) {
                            node.endpoint = endpoint;
                            needUpdated = YES;
                        }
                        NSString *features = [[info valueForKey:@"features"] componentsJoinedByString:@","];
                        if (features.length > 0) {
                            node.features = features;
                            needUpdated = YES;
                        }
                        if (needUpdated) {
                            @strongify(self);
                            [self updateNode:node];
                        }
                        ret = CHLCodeOK;
                    }
                }
            }
            completion(ret);
        }];
    }
}

- (BOOL)updateNode:(CHNodeModel *)model {
    BOOL res = [self.userDataSource updateNode:model];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicNodeUpdated:) withObject:model.nid];
    }
    return res;
}

- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret {
    BOOL res = [self.userDataSource insertNode:model secret:secret];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicNodesUpdated:) withObject:@[model.nid]];
    }
    return res;
}

- (BOOL)deleteNode:(nullable NSString *)nid {
    [self unbindNode:[self.userDataSource nodeWithNID:nid]];
    BOOL res = [self.userDataSource deleteNode:nid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicNodesUpdated:) withObject:@[]];
    }
    return res;
}

- (void)insertNode:(CHNodeModel *)model completion:(nullable CHLogicBlock)completion {
    if (model.endpoint.length <= 0) {
        call_completion(completion, CHLCodeFailed);
    } else {
        BOOL device = model.isStoreDevice;
        @weakify(self);
        CHUserModel *user = self.me;
        NSDictionary *parameters = @{
            @"user": @{
                    @"uid": user.uid,
                    @"key": user.key.pubkey.base64,
            },
        };
        if (device) {
            CHDevice *dev = CHDevice.shared;
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
            [params setValue:@{
                @"uuid": dev.uuid.hex,
                @"key": dev.key.pubkey.base64,
                @"push-token": self.pushToken.base64,
                @"sandbox": @(kCHNotificationSandbox),
                @"type": @(dev.type),
            } forKey:@"device"];
            parameters = params;
        }
        [self sendToEndpoint:model.apiURL cmd:@"bind-user" device:device seckey:model.requestChiper user:self.me parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            @strongify(self);
            CHLCode ret = CHLCodeFailed;
            if (error != nil) {
                if ([response isKindOfClass:NSHTTPURLResponse.class] && [(NSHTTPURLResponse *)response statusCode] == 406) {
                    ret = CHLCodeReject;
                }
                CHLogE("Bind node user failed: %s", error.description.cstr);
            } else {
                CHLogI("Bind node user success.");
                NSData *key = [user.key decode:[NSData dataFromBase64:[result valueForKey:@"key"]]];
                if (key.length > 0 && [self insertNode:model secret:key]) {
                    [self.nsDataSource updateKey:key uid:[NSString stringWithFormat:@"%@.%@", self.me.uid, model.nid]];
                    ret = CHLCodeOK;
                }
            }
            call_completion(completion, ret);
        }];
    }
}

- (void)loadNodeWitEndpoint:(NSString *)endpoint completion:(nullable CHLogicResultBlock)completion {
    NSURL *url = [NSURL URLWithString:[endpoint stringByAppendingPathComponent:@"/rest/v1/info"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:kCHNodeServerRequestTimeout];
    [request setHTTPMethod:@"GET"];
    [request setValue:CHDevice.shared.userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        CHLCode ret = CHLCodeFailed;
        NSDictionary *result = nil;
        if (error == nil) {
            result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];;
            if (result != nil) {
                ret = CHLCodeOK;
            }
            if ([[result valueForKey:@"version"] compareAsVersion:@kCHNodeCanCipherVersion]) {
                ret = CHLCodeFailed;
                CHSecKey *secKey = [CHSecKey secKeyWithPublicKeyData:[NSData dataFromBase64:[result valueForKey:@"pubkey"]]];
                if (secKey != nil) {
                    NSData *sign = [NSData dataFromBase64:[(NSHTTPURLResponse *)response valueForHTTPHeaderField:@"CHSign-Node"]];
                    if ([secKey verify:data sign:sign]) {
                        ret = CHLCodeOK;
                    }
                }
            }
        }
        call_completion_data(completion, ret, result);
    }];
    [task resume];
}

- (BOOL)nodeIsConnected:(nullable NSString *)nid {
    if (nid.length > 0) {
        return ![self.invalidNodes containsObject:nid];
    }
    return NO;
}

- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion {
    if (nid.length > 0) {
        CHNodeModel *node = [self.userDataSource nodeWithNID:nid];
        if (node.isStoreDevice) {
            [self updatePushToken:self.pushToken endpoint:node.apiURL node:node completion:completion retry:NO];
        }
    }
}

#pragma mark - Channels
- (BOOL)insertChannel:(NSString *)code name:(NSString *)name icon:(nullable NSString *)icon {
    BOOL res = NO;
    CHChannelModel *model = [CHChannelModel modelWithCode:code name:name icon:icon];
    if (model != nil) {
        res = [self.userDataSource insertChannel:model];
        if (res) {
            [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[model.cid]];
        }
    }
    return res;
}

- (BOOL)updateChannel:(CHChannelModel *)model {
    BOOL res = [self.userDataSource updateChannel:model];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:model.cid];
    }
    return res;
}

- (BOOL)deleteChannel:(nullable NSString *)cid {
    BOOL res = [self.userDataSource deleteChannel:cid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[cid]];
    }
    return res;
}

#pragma mark - Messages
- (BOOL)deleteMessage:(nullable NSString *)mid {
    CHMessageModel *model = [self.userDataSource messageWithMID:mid];
    BOOL res = [self.userDataSource deleteMessage:mid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicMessageDeleted:) withObject:model];
        [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[]];
    }
    return res;
}

- (BOOL)deleteMessages:(NSArray<NSString *> *)mids {
    BOOL res = [self.userDataSource deleteMessages:mids];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicMessagesDeleted:) withObject:mids];
        [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[]];
    }
    return res;
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
    return (self.watchSession != nil && self.watchSession.activationState == WCSessionActivationStateActivated && self.watchSession.isPaired);
}

- (BOOL)isWatchAppInstalled {
    BOOL res = (self.hasWatch && self.watchSession.isWatchAppInstalled);
    return res;
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

#pragma mark - Private Methods
- (void)updatePushToken:(NSData *)pushToken endpoint:(NSURL *)endpoint node:(nullable CHNodeModel *)node completion:(nullable CHLogicBlock)completion retry:(BOOL)retry {
    if (self.me != nil) {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
            @"token": pushToken.base64,
            @"sandbox": @(kCHNotificationSandbox),
        };
        @weakify(self);
        [self sendToEndpoint:endpoint cmd:@"push-token" device:YES seckey:node.requestChiper user:self.me parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            CHLCode ret = CHLCodeFailed;
            @strongify(self);
            if (error == nil) {
                CHLogI("Update push token to %s success.", endpoint.host.cstr);
                [self tryUpdateNodeStatus:node.nid status:YES];
                ret = CHLCodeOK;
            } else {
                CHLogW("Update push token to %s failed: %s", endpoint.host.cstr, error.description.cstr);
                NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
                if (resp.statusCode == 404 && retry) {
                    [self bindAccount:nil completion:^(CHLCode result) {
                        @strongify(self);
                        [self updatePushToken:pushToken endpoint:endpoint node:node completion:completion retry:NO];
                    }];
                } else {
                    [self tryUpdateNodeStatus:node.nid status:NO];
                }
            }
            call_completion(completion, ret);
        }];
    }
}

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [self updateUserModel:user];
    [self reloadUserDB];
    self.userDataSource.srvkey = key;
    [self.nsDataSource updateKey:key uid:self.me.uid];
    [self updatePushMessage:NO];
    [CHNotification.shared checkAuth];
    // TODO: wait seckey sync to Apple Watch
    [self syncDataToWatch:NO];
}

- (void)doLogout {
    [self.me.key deleteWithName:@kCHUserSecKeyName device:NO];
    [self.nsDataSource updateKey:nil uid:self.me.uid];
    [self.nsDataSource close];
    self.userDataSource.srvkey = nil;
    [self updateUserModel:nil];
    [self reloadUserDB];
    [self updateBadge:0];
    [self syncDataToWatch:NO];
}

- (void)reloadUserDB {
    NSURL *dbpath = nil;
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        NSFileManager *fm = NSFileManager.defaultManager;
        NSURL *dirpath = [fm.URLForDocumentDirectory URLByAppendingPathComponent:uid];
        if ([fm fixDirectory:dirpath]) {
            dbpath = [dirpath URLByAppendingPathComponent:@kCHDBDataName];
        }
    }
    if (self.userDataSource != nil) {
        if (uid.length <= 0 || ![self.userDataSource.dsURL isEqual:dbpath]) {
            [self.userDataSource close];
            _userDataSource = nil;
        }
    }
    if (uid.length > 0) {
        if (self.userDataSource == nil) {
            _userDataSource = [CHUserDataSource dataSourceWithURL:dbpath];
        }
    }
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

- (void)updateNodeBind {
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        if (node.isStoreDevice) {
            [self insertNode:node completion:nil];
        }
    }
}

- (void)unbindNode:(nullable CHNodeModel *)node {
    if (node.isStoreDevice) {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
        };
        [self sendToEndpoint:node.apiURL cmd:@"unbind-user" device:YES seckey:node.requestChiper user:self.me parameters:parameters completion:nil];
    }
}

- (void)tryUpdateNodeStatus:(nullable NSString *)nodeId status:(BOOL)status {
    if (nodeId.length > 0) {
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self updateNodeStatus:nodeId status:status];
        });
    }
}

- (void)updateNodeStatus:(nullable NSString *)nodeId status:(BOOL)status {
    if ([self.invalidNodes containsObject:nodeId] == status) {
        if (status) {
            [self.invalidNodes removeObject:nodeId];
        } else {
            [self.invalidNodes addObject:nodeId];
        }
        [self sendNotifyWithSelector:@selector(logicNodeUpdated:) withObject:nodeId];
    }
}

- (void)updatePushMessage:(BOOL)alert {
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        __block BOOL unreadChanged = NO;
        __block BOOL needAlertUnread= NO;
        NSMutableSet<NSString *> *cids = [NSMutableSet new];
        NSMutableArray<NSString *> *mids = [NSMutableArray new];
        [self.nsDataSource enumerateMessagesWithUID:uid block:^(FMDatabase *db, NSString *mid, NSData *data) {
            CHUpsertMessageFlags flags = 0;
            CHMessageModel *msg = [self.userDataSource upsertMessageData:data ks:[CHTempKeyStorage keyStorage:db] uid:uid mid:mid checker:^BOOL(NSString * _Nonnull cid) {
                return ![self isReadChannel:cid];
            } flags:&flags];
            if (msg != nil) {
                if (flags & CHUpsertMessageFlagChannel) {
                    [cids addObject:msg.channel.base64];
                }
                if (flags & CHUpsertMessageFlagUnread) {
                    unreadChanged = YES;
                    if ([msg.sound boolValue] > 0) {
                        needAlertUnread = YES;
                    }
                }
            }
            if (mid.length > 0) {
                [mids addObject:mid];
            }
        }];
        if (mids.count > 0) {
            [self.nsDataSource removeMessages:mids uid:uid];
            [self sendNotifyWithSelector:@selector(logicMessagesUpdated:) withObject:mids];
        }
        [self.nsDataSource close];
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

- (BOOL)isReadChannel:(NSString *)cid {
    return [self.readChannels containsObject:cid];
}

- (NSData *)watchSyncedData {
    CHTPWatchConfig *cfg = [CHTPWatchConfig new];
    CHUserModel *me = self.me;
    if (me != nil) {
        cfg.userKey = me.key.seckey;
        for (CHNodeModel *node in self.userDataSource.loadNodes) {
            if (node.isSupportWatch && ![node.nid isEqualToString:@"sys"]) {
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

static inline void call_completion_data(CHLogicResultBlock completion, CHLCode result, NSDictionary *data) {
    if (completion != nil) {
        dispatch_main_async(^{
            completion(result, data);
        });
    }
}


@end
