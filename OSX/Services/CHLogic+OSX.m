//
//  CHLogic+OSX.m
//  OSX
//
//  Created by WizJin on 2021/5/2.
//

#import "CHLogic+OSX.h"
#import <AppKit/AppKit.h>
#import <UserNotifications/UserNotifications.h>
#import "CHNotification+Badge.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHMessageModel.h"

@interface CHLogic () <CHNotificationMessageDelegate>

@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *readChannels;

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
    if (self = [super initWithAppGroup:@kCHAppOSXGroupName]) {
        _readChannels = [NSMutableSet new];
        CHNotification.shared.delegate = self;
    }
    return self;
}

- (void)active {
    [super active];
    [self updateMessagesUnreadChanged];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
    if (userInfo != nil) {
        NSData *data = nil;
        NSString *mid = nil;
        NSString *uid = [CHMessageModel parsePacket:userInfo mid:&mid data:&data];
        if (uid.length > 0 && mid.length > 0 && data.length > 0 && [uid isEqualToString:self.me.uid]) {
            CHUpsertMessageFlags flags= 0;
            CHMessageModel *model = [self.userDataSource upsertMessageData:data ks:self.nsDataSource uid:uid mid:mid nsDB:self.nsDataSource checker:^BOOL(NSString * _Nonnull cid) {
                return ![self isReadChannel:cid];
            } flags:&flags];
            if (model != nil) {
                if (flags & CHUpsertMessageFlagChannel) {
                    [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:model.channel.base64];
                }
                [self sendNotifyWithSelector:@selector(logicMessagesUpdated:) withObject:@[mid]];
                if (flags & CHUpsertMessageFlagUnread) {
                    [self updateMessagesUnreadChanged];
                }
            }
        }
    }
}

#pragma mark - CHNotificationMessageDelegate
- (void)registerForRemoteNotifications {
    dispatch_main_async(^{
        [NSApplication.sharedApplication registerForRemoteNotifications];
    });
}

- (void)receiveNotification:(UNNotification *)notification {
    [self receiveRemoteNotification:notification.request.content.userInfo];
}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {
    [self receiveRemoteNotification:response.notification.request.content.userInfo];
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

#pragma mark - Private Methods
- (BOOL)isReadChannel:(NSString *)cid {
    return [self.readChannels containsObject:cid];
}

- (BOOL)clearUnreadWithChannel:(nullable NSString *)cid {
    BOOL res = [self.userDataSource clearUnreadWithChannel:cid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:cid];
        [self updateMessagesUnreadChanged];
    }
    return res;
}

- (void)updateMessagesUnreadChanged {
    NSInteger count = self.userDataSource.unreadSumAllChannel;
    if (count != CHNotification.shared.notificationBadge) {
        CHNotification.shared.notificationBadge = count;
        [self sendNotifyWithSelector:@selector(logicMessagesUnreadChanged:) withObject:@(count)];
    }
}


@end
