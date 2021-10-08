//
//  CHLogic.m
//  iOS
//
//  Created by WizJin on 2021/6/9.
//

#import "CHLogic.h"
#import "CHNSDataSource.h"
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHWebLinkManager.h"
#import "CHWebFileManager.h"
#import "CHWebImageManager.h"
#import "CHWebAudioManager.h"

@interface CHAppLogic ()

@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *readChannels;

@end

@implementation CHAppLogic

- (instancetype)initWithAppGroup:(NSString *)appGroup {
    if (self = [super initWithAppGroup:appGroup]) {
        _readChannels = [NSMutableSet new];
        _webLinkManager = nil;
        _webImageManager = nil;
        _webAudioManager = nil;
        _webFileManager = nil;
    }
    return self;
}

#pragma mark - Channels
- (BOOL)insertChannel:(CHChannelModel *)model {
    BOOL res = [self.userDataSource insertChannel:model] && [self.nsDataSource insertChannel:model uid:self.me.uid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicChannelsUpdated:) withObject:@[model.cid]];
    }
    return res;
}

- (BOOL)updateChannel:(CHChannelModel *)model {
    BOOL res = [self.userDataSource updateChannel:model] && [self.nsDataSource updateChannel:model uid:self.me.uid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:model.cid];
    }
    return res;
}

- (BOOL)deleteChannel:(nullable NSString *)cid {
    BOOL res = [self.userDataSource deleteChannel:cid] && [self.nsDataSource deleteChannel:cid uid:self.me.uid];
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

- (BOOL)deleteMessagesWithCID:(nullable NSString *)cid {
    BOOL res = [self.userDataSource deleteMessagesWithCID:cid];
    if (res) {
        [self sendNotifyWithSelector:@selector(logicMessagesCleared:) withObject:cid];
        [self sendNotifyWithSelector:@selector(logicChannelUpdated:) withObject:cid];
        
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

- (BOOL)isReadChannel:(NSString *)cid {
    return [self.readChannels containsObject:cid];
}

- (NSArray<NSString *> *)readChannelIDs {
    return self.readChannels.allObjects;
}

#pragma mark - Subclass Methods
- (void)reloadUserDB:(BOOL)force {
    [super reloadUserDB:force];
    NSString *uid = self.me.uid;
    NSURL *dbpath = [self dbPath:uid];
    if (self.webImageManager != nil && ![self.webImageManager.uid isEqualToString:uid]) {
        [self.webImageManager close];
        _webImageManager = nil;
    }
    if (self.webAudioManager != nil && ![self.webAudioManager.uid isEqualToString:uid]) {
        [self.webAudioManager close];
        _webAudioManager = nil;
    }
    if (self.webFileManager != nil && ![self.webFileManager.uid isEqualToString:uid]) {
        [self.webFileManager close];
        _webFileManager = nil;
    }
    if (self.webLinkManager != nil && ![self.webLinkManager.uid isEqualToString:uid]) {
        [self.webLinkManager close];
        _webLinkManager = nil;
    }
    if (uid.length > 0) {
        NSURL *basePath = [dbpath.URLByDeletingLastPathComponent URLByAppendingPathComponent:@kCHWebBasePath];
        if (_webImageManager == nil) {
            _webImageManager = [CHWebImageManager webImageManagerWithURL:[basePath URLByAppendingPathComponent:@"images"]];
            self.webImageManager.uid = uid;
        }
        if (_webAudioManager == nil) {
            _webAudioManager = [CHWebAudioManager webAudioManagerWithURL:[basePath URLByAppendingPathComponent:@"audios"]];
            self.webAudioManager.uid = uid;
        }
        if (_webFileManager == nil) {
            _webFileManager = [CHWebFileManager webFileManagerWithURL:[basePath URLByAppendingPathComponent:@"files"]];
            self.webFileManager.uid = uid;
        }
        if (_webLinkManager == nil) {
            _webLinkManager = [CHWebLinkManager webLinkManagerWithURL:[basePath URLByAppendingPathComponent:@"links"]];
            self.webLinkManager.uid = uid;
        }
    }
}

- (BOOL)clearUnreadWithChannel:(nullable NSString *)cid {
    return NO;
}


@end
