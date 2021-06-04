//
//  CHLogic+iOS.h
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic.h"

NS_ASSUME_NONNULL_BEGIN

@class UIImage;
@class CHNodeModel;
@class CHChannelModel;
@class CHMessageModel;
@class CHWebLinkManager;
@class CHWebFileManager;
@class CHWebImageManager;
@class CHWebAudioManager;

@protocol CHLogicDelegate <CHCommonLogicDelegate>
@optional
- (void)logicWatchStatusChanged;
- (void)logicChannelUpdated:(NSString *)cid;
- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids;
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids;
- (void)logicMessageDeleted:(CHMessageModel *)mid;
- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids;
- (void)logicMessagesCleared:(NSString *)cid;
- (void)logicMessagesUnreadChanged:(NSNumber *)unread;
- (void)logicBlockedTokenChanged;
@end

@interface CHLogic : CHCommonLogic<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;
@property (nonatomic, nullable, readonly, strong) CHWebLinkManager *webLinkManager;
@property (nonatomic, nullable, readonly, strong) CHWebFileManager *webFileManager;
@property (nonatomic, nullable, readonly, strong) CHWebImageManager *webImageManager;
@property (nonatomic, nullable, readonly, strong) CHWebAudioManager *webAudioManager;

// API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion;
// Nodes
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion;
// Channels
- (BOOL)insertChannel:(NSString *)code name:(nullable NSString *)name icon:(nullable NSString *)icon;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;
// Messages
- (BOOL)deleteMessage:(nullable NSString *)mid;
- (BOOL)deleteMessages:(NSArray<NSString *> *)mids;
- (BOOL)deleteMessagesWithCID:(nullable NSString *)cid;
// Read & Unread
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (void)addReadChannel:(nullable NSString *)cid;
- (void)removeReadChannel:(nullable NSString *)cid;
// Blocklist
- (void)upsertBlockedToken:(NSString *)token;
- (void)removeBlockedTokens:(NSArray<NSString *> *)tokens;
- (NSArray<NSString *> *)blockedTokens;
// Watch
- (BOOL)hasWatch;
- (BOOL)isWatchAppInstalled;
- (BOOL)syncDataToWatch:(BOOL)focus;


@end

NS_ASSUME_NONNULL_END
