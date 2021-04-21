//
//  CHLogic+watchOS.m
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic+watchOS.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate>

@property (nonatomic, readonly, strong) WCSession *session;
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
        _pushToken = [NSData new];
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
        
        assert(WCSession.isSupported);
        _session = WCSession.defaultSession;
        self.session.delegate = self;
        [self.session activateSession];
    }
    return self;
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

#pragma mark - Private Methods
- (void)updateContext:(WCSession *)session {
    NSData *data = [session.receivedApplicationContext objectForKey:@"data"];
    NSError *error = nil;
    CHTPWatchConfig *cfg = [CHTPWatchConfig parseFromData:data ?: [NSData new] error:&error];
    if (error == nil) {
        _me = [CHUserModel modelWithKey:[CHSecKey secKeyWithData:cfg.userKey]];
    }
    [self sendNotifyWithSelector:@selector(logicUserInfoChanged:) withObject:self.me];
}


@end
