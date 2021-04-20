//
//  CHWatchLogic.m
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

#import "CHWatchLogic.h"
#import "CHTP.pbobjc.h"

@implementation CHWatchLogic

- (instancetype)init {
    if (self = [super init]) {
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
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        [self updateContext:session];
    });
}

#pragma mark - Private Methods
- (void)updateContext:(WCSession *)session {
    NSData *data = [session.receivedApplicationContext objectForKey:@"data"];
    _me = nil;
    if (data.length > 0) {
        NSError *error = nil;
        CHTPWatchConfig *cfg = [CHTPWatchConfig parseFromData:data error:&error];
        if (error == nil && cfg != nil) {
            CHSecKey *key = [CHSecKey secKeyWithData:cfg.userKey];
            if (key != nil) {
                _me = [CHUserModel modelWithKey:key];
            }
        }
    }
    [self onUpdateUserInfo];
}

#pragma mark - Event Methods
- (void)onUpdateUserInfo {
}


@end
