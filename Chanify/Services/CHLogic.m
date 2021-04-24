//
//  CHLogic.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLogic.h"
#import "CHUserDataSource.h"
#import "CHNotification.h"
#import "CHDevice.h"
#import "CHCrpyto.h"

@interface CHCommonLogic ()

@property (nonatomic, readonly, strong) NSURLSession *session;

@end

@implementation CHCommonLogic

- (instancetype)init {
    if (self = [super init]) {
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
        _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%s/rest/v1/", kCHAPIHostname]];
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _userDataSource = nil;
    }
    return self;
}


- (void)launch {
    [CHNotification.shared checkAuth];
}

- (void)active {
    [CHNotification.shared updateStatus];
    [self reloadUserDB:NO];
}

- (void)deactive {
    [self.userDataSource close]; // only close db, not clear point
}

- (void)resetData {
    if (self.userDataSource != nil) {
        [self.userDataSource close];
        [NSFileManager.defaultManager removeItemAtPath:self.userDataSource.dsURL.path error:nil];
        _userDataSource = nil;
        [self reloadUserDB:NO];
    }
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


@end
