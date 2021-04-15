//
//  CHLogic.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLogic.h"
#import <AFNetworking/AFNetworking.h>
#import "CHWebObjectManager.h"
#import "CHWebFileManager.h"
#import "CHLinkMetaManager.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHMessageModel.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHNotification.h"
#import "CHDevice.h"
#import "CHCrpyto.h"

#if DEBUG
#   define kSandbox    YES
#else
#   define kSandbox    NO  // TestFlight use production APNS.
#endif

@interface CHLogic ()

@property (nonatomic, readonly, strong) NSURL *baseURL;
@property (nonatomic, readonly, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) AFURLSessionManager *manager;
@property (nonatomic, readonly, strong) NSData *pushToken;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *invalidNodes;

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
        NSFileManager *fileManager = NSFileManager.defaultManager;
        CHDevice *device = CHDevice.shared;
        _pushToken = [NSData new];
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
        _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%s/rest/v1/", kCHAPIHostname]];
        _userAgent = [NSString stringWithFormat:@"%@/%@-%d (%@; %@; Scale/%0.2f)", device.app, device.version, device.build, device.model, device.osInfo, device.scale];
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _nsDataSource = [CHNSDataSource dataSourceWithURL:[fileManager URLForGroupId:@kCHAppGroupName path:@kCHDBNotificationServiceName]];
        _userDataSource = nil;
        _webImageManager = nil;
        _webFileManager = nil;
        _linkMetaManager = nil;
        _invalidNodes = [NSMutableSet new];
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
    [self reloadUserDB];
    [self updatePushMessage];
    [self clearBadge];
}

- (void)deactive {
    [self clearBadge];
    [self.nsDataSource close];
    [self.userDataSource close];
}

- (void)resetData {
    if (self.userDataSource != nil) {
        [self.userDataSource close];
        [NSFileManager.defaultManager removeItemAtPath:self.userDataSource.dsURL.path error:nil];
        _userDataSource = nil;
        [self reloadUserDB];
    }
}

- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion {
    [self bindAccount:[CHSecKey new] completion:completion];
}

- (void)logoutWithCompletion:(nullable CHLogicBlock)completion {
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        [self unbindNode:node];
    }
    if (_me == nil) {
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

- (BOOL)recivePushMessage:(NSDictionary *)userInfo {
    // TODO: Remove this update call.
    [self updatePushMessage];

    BOOL res = NO;
    NSData *data = nil;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:userInfo mid:&mid data:&data];
    if (uid.length > 0 && [uid isEqualToString:self.me.uid] && mid.length > 0 && data.length > 0) {
        NSString *cid = nil;
        if ([self.userDataSource upsertMessageData:data ks:self.nsDataSource uid:uid mid:mid cid:&cid]) {
            if (cid != nil) {
                [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[]];
            }
            [self sendNotifyWithSelector:@selector(logicMessagesUpdated:) withObject:@[mid]];
            res = YES;
        }
    }
    return res;
}

- (void)updatePushToken:(NSData *)pushToken {
    _pushToken = pushToken ?: [NSData new];
    [self updatePushToken:pushToken endpoint:self.baseURL node:nil completion:nil retry:YES];
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        if (node.isStoreDevice) {
            [self updatePushToken:pushToken endpoint:node.apiURL node:node completion:nil retry:NO];
        }
    }
}

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

- (void)updateNodeInfo:(nullable NSString*)nid completion:(nullable CHLogicBlock)completion {
    CHNodeModel *node = [self.userDataSource nodeWithNID:nid];
    if (node != nil && !node.isSystem) {
        @weakify(self);
        [CHLogic.shared loadNodeWitEndpoint:node.endpoint completion:^(CHLCode result, NSDictionary *info) {
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
                @"sandbox": @(kSandbox),
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
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask *task = [self.manager.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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

#pragma mark - Message Methods
- (void)bindAccount:(CHSecKey *)key completion:(nullable CHLogicBlock)completion {
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
            } else {
                CHLogI("Bind account success.");
                @strongify(self);
                if ((self->_me == user) // Note: is retry
                    || [user.key saveTo:@kCHUserSecKeyName device:NO]) {
                    [self doLogin:user key:[user.key decode:[NSData dataFromBase64:[result valueForKey:@"key"]]]];
                    ret = CHLCodeOK;
                }
            }
            call_completion(completion, ret);
        }];
    }
}

- (void)updatePushToken:(NSData *)pushToken endpoint:(NSURL *)endpoint node:(nullable CHNodeModel *)node completion:(nullable CHLogicBlock)completion retry:(BOOL)retry {
    if (self.me != nil) {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
            @"token": pushToken.base64,
            @"sandbox": @(kSandbox),
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

- (void)sendCmd:(NSString *)cmd user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion {
    [self sendToEndpoint:self.baseURL cmd:cmd device:YES seckey:nil user:user parameters:parameters completion:completion];
}

- (void)sendToEndpoint:(NSURL *)endpoint cmd:(NSString *)cmd device:(BOOL)device seckey:(nullable CHSecKey *)seckey user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [params setValue:@((uint64_t)(NSDate.date.timeIntervalSince1970 * 1000)) forKey:@"nonce"];
    NSData *data = params.json;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[endpoint URLByAppendingPathComponent:cmd]];
    [request setTimeoutInterval:kCHNodeServerRequestTimeout];
    [request setHTTPMethod:@"POST"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    if (seckey == nil) {
        [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    } else {
        [request setValue:@"application/x-chsec-json" forHTTPHeaderField:@"Content-Type"];
        data = [seckey encode:data];
    }
    if (device) {
        [request setValue:[CHDevice.shared.key sign:data].base64 forHTTPHeaderField:@"CHDevSign"];
    }
    [request setValue:[user.key sign:data].base64 forHTTPHeaderField:@"CHUserSign"];
    [request setHTTPBody:data];
    NSURLSessionDataTask *task = [self.manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
        if (completion != nil) {
            completion(response, result, error);
        }
    }];
    [task resume];
}

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    _me = user;
    [self reloadUserDB];
    [self updatePushMessage];
    self.userDataSource.srvkey = key;
    [self.nsDataSource updateKey:key uid:self.me.uid];
    [CHNotification.shared checkAuth];
}

- (void)doLogout {
    [self.me.key deleteWithName:@kCHUserSecKeyName device:NO];
    [self.nsDataSource updateKey:nil uid:self.me.uid];
    self.userDataSource.srvkey = nil;
    [self clearBadge];
    [self.nsDataSource close];
    [self reloadUserDB];
    _me = nil;
}

- (void)clearBadge {
    CHNotification.shared.notificationBadge = 0;
    [self.nsDataSource updateBadge:0 uid:self.me.uid];
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
        if (self.userDataSource == nil) {
            _userDataSource = [CHUserDataSource dataSourceWithURL:dbpath];
        }
        
        NSURL *basePath = [dbpath.URLByDeletingLastPathComponent URLByAppendingPathComponent:@kCHWebBasePath];
        if (_webImageManager == nil) {
            _webImageManager = [CHWebObjectManager webObjectManagerWithURL:[basePath URLByAppendingPathComponent:@"images"] decoder:[CHWebImageDecoder new] userAgent:self.userAgent];
            self.webImageManager.uid = uid;
        }
        if (_webFileManager == nil) {
            _webFileManager = [CHWebFileManager webFileManagerWithURL:[basePath URLByAppendingPathComponent:@"files"] userAgent:self.userAgent];
            self.webFileManager.uid = uid;
        }
        if (_linkMetaManager == nil) {
            _linkMetaManager = [CHLinkMetaManager linkManagerWithURL:[basePath URLByAppendingPathComponent:@"links"]];
            self.linkMetaManager.uid = uid;
        }
    }
}

- (void)updatePushMessage {
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        __block BOOL channelUpdated = NO;
        NSMutableArray<NSString *> *mids = [NSMutableArray new];
        [self.nsDataSource enumerateMessagesWithUID:uid block:^(FMDatabase *db, NSString *mid, NSData *data) {
            NSString *cid = nil;
            if ([self.userDataSource upsertMessageData:data ks:[CHTempKeyStorage keyStorage:db] uid:uid mid:mid cid:&cid]) {
                if (cid != nil) {
                    channelUpdated = YES;
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
        if (channelUpdated) {
            [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[]];
        }
    }
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
