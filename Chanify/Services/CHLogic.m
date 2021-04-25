//
//  CHLogic.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLogic.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHNotification.h"
#import "CHNodeModel.h"
#import "CHDevice.h"
#import "CHCrpyto.h"

@interface CHCommonLogic ()

@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *invalidNodes;

@end

@implementation CHCommonLogic

- (instancetype)initWithAppGroup:(NSString *)appGroup {
    if (self = [super init]) {
        CHLogI("User agent: %s", CHDevice.shared.userAgent.cstr);
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
        _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%s/rest/v1/", kCHAPIHostname]];
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _invalidNodes = [NSMutableSet new];
        _nsDataSource = [CHNSDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:appGroup path:@kCHDBNotificationServiceName]];
        _userDataSource = nil;
    }
    return self;
}

- (void)launch {
    [CHNotification.shared checkAuth];
    [self reloadUserDB:NO];
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
    [self reloadUserDB:NO];
}

- (void)deactive {
    [self.nsDataSource flush];
    [self.userDataSource flush];
}

- (void)resetData {
    if (self.userDataSource != nil) {
        [self.userDataSource close];
        [NSFileManager.defaultManager removeItemAtPath:self.userDataSource.dsURL.path error:nil];
        _userDataSource = nil;
        [self reloadUserDB:NO];
    }
    [self.invalidNodes removeAllObjects];
}

- (void)reloadUserDB:(BOOL)force {
    NSString *uid = self.me.uid;
    NSURL *dbpath = [self dbPath:uid];
    if (force || ![self.userDataSource.dsURL isEqual:dbpath]) {
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
    }
}

- (nullable NSURL *)dbPath:(nullable NSString *)uid {
    NSURL *dbpath = nil;
    if (uid.length > 0) {
        NSFileManager *fm = NSFileManager.defaultManager;
        NSURL *dirpath = [fm.URLForDocumentDirectory URLByAppendingPathComponent:uid];
        if ([fm fixDirectory:dirpath]) {
            dbpath = [dirpath URLByAppendingPathComponent:@kCHDBDataName];
        }
    }
    return dbpath;
}

- (void)updatePushToken:(NSData *)pushToken {
    [CHNotification.shared updateDeviceToken:pushToken];
    if (self.me != nil) {
        [self updatePushToken:pushToken endpoint:self.baseURL node:nil completion:nil retry:YES];
        for (CHNodeModel *node in self.userDataSource.loadNodes) {
            if (node.isStoreDevice) {
                [self updatePushToken:pushToken endpoint:node.apiURL node:node completion:nil retry:YES];
            }
        }
    }
}

- (void)updatePushToken:(NSData *)pushToken node:(CHNodeModel *)node completion:(nullable CHLogicBlock)completion {
    [self updatePushToken:pushToken endpoint:node.apiURL node:node completion:completion retry:NO];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
    [CHNotification.shared receiveRemoteNotification:userInfo];
}

- (void)updateUserModel:(nullable CHUserModel *)me {
    _me = me;
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
    [request setValue:CHDevice.shared.userAgent forHTTPHeaderField:@"User-Agent"];
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
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion != nil) {
            NSDictionary *result = nil;
            if (error == nil) {
                result = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves) error:&error];
            }
            dispatch_main_async(^{
                completion(response, result, error);
            });
        }
    }];
    [task resume];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    return [self.session dataTaskWithRequest:request completionHandler:completionHandler];
}

#pragma mark - API
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

- (void)logoutWithCompletion:(nullable CHLogicBlock)completion {
    if (self.me == nil) {
        call_completion(completion, CHLCodeOK);
    } else {
        for (CHNodeModel *node in self.userDataSource.loadNodes) {
            [self unbindNode:node];
        }
        
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

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [self updateUserModel:user];
    [self reloadUserDB:YES];
    self.userDataSource.srvkey = key;
    [self.nsDataSource updateKey:key uid:self.me.uid];
    [self updatePushToken:CHNotification.shared.pushToken endpoint:self.baseURL node:nil completion:nil retry:NO];
}

- (void)doLogout {
    [self.me.key deleteWithName:@kCHUserSecKeyName device:NO];
    [self.nsDataSource updateKey:nil uid:self.me.uid];
    [self.nsDataSource close];
    self.userDataSource.srvkey = nil;
    [self updateUserModel:nil];
    [self reloadUserDB:YES];
}

#pragma mark - Nodes
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

- (void)updateNodeInfo:(nullable NSString*)nid completion:(nullable CHLogicBlock)completion {
    CHNodeModel *node = [self.userDataSource nodeWithNID:nid];
    if (node == nil || node.isSystem) {
        call_completion(completion, CHLCodeFailed);
    } else {
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
            call_completion(completion, ret);
        }];
    }
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
                @"push-token": CHNotification.shared.pushToken.base64,
                @"sandbox": @(kCHNotificationSandbox),
                @"type": @(dev.type),
            } forKey:@"device"];
            parameters = params;
        }
        [self sendToEndpoint:model.apiURL cmd:@"bind-user" device:device seckey:model.requestChiper user:self.me parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            @strongify(self);
            CHLCode ret = CHLCodeFailed;
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            if (error == nil && resp.statusCode < 300) {
                CHLogI("Bind node user success.");
                NSData *key = [user.key decode:[NSData dataFromBase64:[result valueForKey:@"key"]]];
                if (key.length > 0 && [self insertNode:model secret:key]) {
                    [self.nsDataSource updateKey:key uid:[NSString stringWithFormat:@"%@.%@", self.me.uid, model.nid]];
                    ret = CHLCodeOK;
                }
            } else {
                if ([response isKindOfClass:NSHTTPURLResponse.class] && [(NSHTTPURLResponse *)response statusCode] == 406) {
                    ret = CHLCodeReject;
                }
                CHLogE("Bind node user failed: %s", (error == nil ? [NSString stringWithFormat:@"%ld", (long)resp.statusCode] : error.description).cstr);
            }
            call_completion(completion, ret);
        }];
    }
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

- (BOOL)updateNode:(CHNodeModel *)model {
    BOOL res = [self.userDataSource updateNode:model];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicNodeUpdated:) withObject:model.nid];
    }
    return res;
}

- (nullable CHNodeModel *)nodeModelWithNID:(nullable NSString *)nid {
    return [self.userDataSource nodeWithNID:nid];
}

- (BOOL)nodeIsConnected:(nullable NSString *)nid {
    if (nid.length > 0) {
        return ![self.invalidNodes containsObject:nid];
    }
    return NO;
}

#pragma mark - Private Methods
- (void)bindNodeAccount:(nullable CHNodeModel *)model completion:(nullable CHLogicBlock)completion {
    if (model == nil || model.isSystem) {
        [self bindAccount:nil completion:completion];
    } else {
        [self insertNode:model completion:completion];
    }
}

- (void)updateNodeBind {
    @weakify(self);
    for (CHNodeModel *node in self.userDataSource.loadNodes) {
        if (node.isStoreDevice) {
            [self insertNode:node completion:^(CHLCode result) {
                if (result == CHLCodeOK) {
                    @strongify(self);
                    [self updatePushToken:CHNotification.shared.pushToken endpoint:node.apiURL node:node completion:nil retry:NO];
                }
            }];
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
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            if (error == nil && resp.statusCode < 300) {
                CHLogI("Update push token to %s success.", endpoint.host.cstr);
                [self tryUpdateNodeStatus:node.nid status:YES];
                ret = CHLCodeOK;
            } else {
                CHLogW("Update push token to %s failed: %s", endpoint.host.cstr, (error == nil ? [NSString stringWithFormat:@"%ld", (long)resp.statusCode] : error.description).cstr);
                if (resp.statusCode == 404 && retry) {
                    [self bindNodeAccount:node completion:^(CHLCode result) {
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
