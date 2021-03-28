//
//  CHLogic.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLogic.h"
#import <AFNetworking/AFNetworking.h>
#import "CHWebFileManager.h"
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
        _pushToken = nil;
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
        _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%s/rest/v1/", kCHAPIHostname]];
        _userAgent = [NSString stringWithFormat:@"%@/%@-%d (%@; %@; Scale/%0.2f)", device.app, device.version, device.build, device.model, device.osInfo, device.scale];
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _nsDataSource = [CHNSDataSource dataSourceWithURL:[fileManager URLForGroupId:@kCHAppGroupName path:@kCHDBNotificationServiceName]];
        _userDataSource = nil;
        _imageFileManager = nil;
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
    _pushToken = pushToken;
    [self updatePushToken:pushToken endpoint:self.baseURL retry:YES];
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        if (node.flags&CHNodeModelFlagsStoreDevice) {
            [self updatePushToken:pushToken endpoint:node.apiURL retry:NO];
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
        BOOL device = model.flags&CHNodeModelFlagsStoreDevice;
        @weakify(self);
        CHUserModel *user = self.me;
        NSDictionary *parameters = @{
            @"user": @{
                    @"uid": user.uid,
                    @"key": user.key.pubkey.base64,
            },
        };
        if (device) {
            CHDevice *device = CHDevice.shared;
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
            [params setValue:@{
                @"uuid": device.uuid.hex,
                @"key": device.key.pubkey.base64,
                @"push-token": self.pushToken.base64,
                @"sandbox": @(kSandbox),
            } forKey:@"device"];
            parameters = params;
        }
        [self sendToEndpoint:model.apiURL device:device cmd:@"bind-user" user:self.me parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            @strongify(self);
            CHLCode ret = CHLCodeFailed;
            if (error != nil) {
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

- (void)updatePushToken:(NSData *)pushToken endpoint:(NSURL *)endpoint retry:(BOOL)retry {
    if (self.me != nil) {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
            @"token": pushToken.base64,
            @"sandbox": @(kSandbox),
        };
        @weakify(self);
        [self sendToEndpoint:endpoint device:YES cmd:@"push-token" user:self.me parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            if (error == nil) {
                CHLogI("Update push token to %s success.", endpoint.host.cstr);
            } else {
                CHLogW("Update push token to %s failed: %s", endpoint.host.cstr, error.description.cstr);
                NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
                if (resp.statusCode == 404 && retry) {
                    @strongify(self);
                    [self bindAccount:nil completion:^(CHLCode result) {
                        @strongify(self);
                        [self updatePushToken:pushToken endpoint:endpoint retry:NO];
                    }];
                }
            }
        }];
    }
}

- (void)updateNodeBind {
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        if (node.flags&CHNodeModelFlagsStoreDevice) {
            [self insertNode:node completion:nil];
        }
    }
}

- (void)unbindNode:(nullable CHNodeModel *)node {
    if (node != nil && node.flags&CHNodeModelFlagsStoreDevice) {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
        };
        [self sendToEndpoint:node.apiURL device:YES cmd:@"unbind-user" user:self.me parameters:parameters completion:nil];
    }
}

- (void)sendCmd:(NSString *)cmd user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion {
    [self sendToEndpoint:[NSURL URLWithString:cmd relativeToURL:self.baseURL] device:YES cmd:cmd user:user parameters:parameters completion:completion];
}

- (void)sendToEndpoint:(NSURL *)endpoint device:(BOOL)device cmd:(NSString *)cmd user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [params setValue:@((uint64_t)(NSDate.date.timeIntervalSince1970 * 1000)) forKey:@"nonce"];
    NSData *data = params.json;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:cmd relativeToURL:endpoint]];
    [request setHTTPMethod:@"POST"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
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
            
            [self.imageFileManager close];
            _imageFileManager = nil;
        }
    }
    if (uid.length > 0 && self.userDataSource == nil) {
        _userDataSource = [CHUserDataSource dataSourceWithURL:dbpath];

        NSURL *webFilePath = [dbpath.URLByDeletingLastPathComponent URLByAppendingPathComponent:@kCHWebFileBasePath];
        _imageFileManager = [CHWebFileManager webFileManagerWithURL:[webFilePath URLByAppendingPathComponent:@"images"] decoder:[CHWebImageFileDecoder new] userAgent:self.userAgent];
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


@end
