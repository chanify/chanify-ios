//
//  CHLogic.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLogic.h"
#import <AFNetworking/AFNetworking.h>
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHMessageModel.h"
#import "CHNotification.h"
#import "CHDevice.h"

@interface CHLogic ()

@property (nonatomic, readonly, strong) NSURL *baseURL;
@property (nonatomic, readonly, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) AFURLSessionManager *manager;

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
        CHDevice *device = CHDevice.shared;
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
        _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%s/rest/v1/", kCHAPIHostname]];
        _userAgent = [NSString stringWithFormat:@"%@/%@-%d (%@; %@; Scale/%0.2f)", device.app, device.version, device.build, device.model, device.osInfo, device.scale];
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _nsDataSource = [CHNSDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:@kCHAppGroupName path:@kCHDBNotificationServiceName]];
        _userDataSource = nil;
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
        [self bindAccount:seckey completion:completion];
    }
}

- (BOOL)recivePushMessage:(NSDictionary *)userInfo {
    BOOL res = NO;
    NSData *data = nil;
    uint64_t mid = 0;
    NSString *uid = [CHMessageModel parsePacket:userInfo mid:&mid data:&data];
    if (uid.length > 0 && [uid isEqualToString:self.me.uid] && mid > 0 && data.length > 0) {
        if ([self.userDataSource upsertMessageData:data mid:mid]) {
            [self sendNotifyWithSelector:@selector(logicMessageUpdated:) withObject:@[@(mid)]];
            res = YES;
        }
    }
    return res;
}

- (void)updatePushToken:(NSData *)pushToken {
    [self updatePushToken:pushToken retry:YES];
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

- (void)updatePushToken:(NSData *)pushToken retry:(BOOL)retry {
    if (self.me != nil) {
        CHDevice *device = CHDevice.shared;
        NSDictionary *parameters = @{
            @"device": device.uuid.hex,
            @"user": self.me.uid,
            @"token": pushToken.base64,
            @"sandbox": @(device.sandbox),
        };
        @weakify(self);
        [self sendCmd:@"push-token" user:self.me parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
            if (error == nil) {
                CHLogI("Update push token success.");
            } else {
                CHLogW("Update push token failed: %s", error.description.cstr);
                NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
                if (resp.statusCode == 404 && retry) {
                    @strongify(self);
                    [self bindAccount:nil completion:^(CHLCode result) {
                        @strongify(self);
                        [self updatePushToken:pushToken retry:NO];
                    }];
                }
            }
        }];
    }
}

- (void)sendCmd:(NSString *)cmd user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion {
    CHDevice *device = CHDevice.shared;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [params setValue:@((uint64_t)(NSDate.date.timeIntervalSince1970 * 1000)) forKey:@"nonce"];
    NSData *data = params.json;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:cmd relativeToURL:self.baseURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[device.key sign:data].base64 forHTTPHeaderField:@"CHDevSign"];
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
    if (uid.length > 0 && self.userDataSource == nil) {
        _userDataSource = [CHUserDataSource dataSourceWithURL:dbpath];
    }
}

- (void)updatePushMessage {
    NSString *uid = self.me.uid;
    if (uid.length > 0) {
        NSMutableArray<NSNumber *> *mids = [NSMutableArray new];
        [self.nsDataSource enumerateMessagesWithUID:uid block:^(uint64_t mid, NSData *data) {
            if ([self.userDataSource upsertMessageData:data mid:mid]) {
                if (mid > 0) {
                    [mids addObject:@(mid)];
                }
            }
        }];
        if (mids.count > 0) {
            [self.nsDataSource removeMessages:mids uid:uid];
            [self sendNotifyWithSelector:@selector(logicMessageUpdated:) withObject:mids];
        }
        [self.nsDataSource close];
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