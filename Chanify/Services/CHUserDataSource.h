//
//  CHUserDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kCHDefChanCode      "0801"

typedef NS_OPTIONS(NSUInteger, CHUpsertMessageFlags) {
    CHUpsertMessageFlagUnread       = 1 << 0,
    CHUpsertMessageFlagChannel      = 1 << 1,
    // Deliberately rejected by the blocklist; safe to remove from the inbox.
    CHUpsertMessageFlagDiscarded    = 1 << 2,
};

@class CHMessageSearch;
@class CHNodeModel;
@class CHChannelModel;
@class CHMessageModel;
@class CHScriptModel;
@class CHNSDataSource;
@protocol CHKeyStorage;
@protocol CHBlockedStorage;

typedef void (^CHMessageLoadCompletion)(NSArray<CHMessageModel *> *messages, NSError * _Nullable error);

#if TARGET_OS_WATCH
typedef void (^CHWatchMessageLoadCompletion)(NSArray<CHMessageModel *> *messages, NSString * _Nullable nextMID, BOOL hasMore, NSError * _Nullable error);
#endif

@interface CHUserDataSource : NSObject

@property (nonatomic, readonly, strong) NSURL *dsURL;
@property (nonatomic, nullable, strong) NSData *srvkey;

+ (instancetype)dataSourceWithURL:(NSURL *)url;
@property (nonatomic, readonly, nullable, strong) CHMessageSearch *messageSearch;
- (void)close;
- (void)flush;
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret;
- (BOOL)updateNode:(CHNodeModel *)model;
- (BOOL)deleteNode:(nullable NSString *)nid;
- (nullable NSData *)keyForNodeID:(nullable NSString *)nid;
- (NSArray<CHNodeModel *> *)loadNodes;
- (nullable CHNodeModel *)nodeWithNID:(nullable NSString *)nid;
- (BOOL)insertChannel:(CHChannelModel *)model;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;
- (BOOL)channelIsHidden:(nullable NSString *)cid;
- (BOOL)updateChannelWithCID:(nullable NSString *)cid hidden:(BOOL)hidden;
- (NSArray<CHChannelModel *> *)loadAllChannels;
- (NSArray<CHChannelModel *> *)loadChannelsIncludeHidden:(BOOL)hidden;
- (nullable CHChannelModel *)channelWithCID:(nullable NSString *)cid;
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (BOOL)clearUnreadWithChannel:(nullable NSString *)cid;
- (BOOL)deleteMessage:(NSString *)mid;
- (BOOL)deleteMessages:(NSArray<NSString *> *)mids;
- (BOOL)deleteMessagesWithCID:(nullable NSString *)cid;
- (NSArray<CHMessageModel *> *)messageWithCID:(nullable NSString *)cid from:(NSString *)from to:(NSString *)to count:(NSUInteger)count;
#if TARGET_OS_WATCH
// Bounded, resumable repair; completed scans are persisted without a schema change.
- (nullable NSString *)repairWatchMessagesAfterMID:(NSString *)mid storage:(id<CHKeyStorage, CHBlockedStorage>)storage uid:(NSString *)uid limit:(NSUInteger)limit pending:(BOOL *)pending error:(NSError * _Nullable * _Nullable)error;
- (void)loadWatchMessagesBeforeMID:(nullable NSString *)mid count:(NSUInteger)count completion:(CHWatchMessageLoadCompletion)completion;
#endif
- (void)loadMessagesNearMID:(NSString *)mid channelID:(NSString *)cid count:(NSUInteger)count completion:(CHMessageLoadCompletion)completion;
- (void)loadMessagesWithCID:(NSString *)cid from:(NSString *)from to:(NSString *)to count:(NSUInteger)count ascending:(BOOL)ascending completion:(CHMessageLoadCompletion)completion;
- (NSArray<CHMessageModel *> *)messagesNearMID:(NSString *)mid channelID:(NSString *)cid count:(NSUInteger)count;
- (NSArray<CHMessageModel *> *)messagesAfterMID:(NSString *)mid channelID:(NSString *)cid count:(NSUInteger)count;
- (nullable CHMessageModel *)messageWithMID:(nullable NSString *)mid;
- (nullable CHMessageModel *)upsertMessageData:(NSData *)data nsDB:(id<CHKeyStorage, CHBlockedStorage>)nsDB uid:(NSString *)uid mid:(NSString *)mid checker:(BOOL (NS_NOESCAPE ^ _Nullable)(NSString * cid))checker flags:(CHUpsertMessageFlags *)pFlags;
- (NSArray<CHScriptModel *> *)loadScripts;
- (BOOL)insertScript:(CHScriptModel *)model;
- (BOOL)deleteScript:(NSString *)name;
- (nullable CHScriptModel *)scriptWithName:(nullable NSString *)name;
- (NSString *)scriptContentWithName:(nullable NSString *)name type:(NSString *)type;
- (BOOL)updateScriptContent:(NSString *)content name:(NSString *)name;


@end

NS_ASSUME_NONNULL_END
