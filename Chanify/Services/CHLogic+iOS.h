//
//  CHLogic+iOS.h
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic.h"
#import "CHWebObjectManager.h"

NS_ASSUME_NONNULL_BEGIN

@class UIImage;
@class CHNodeModel;
@class CHChannelModel;
@class CHMessageModel;
@class CHNSDataSource;
@class CHUserDataSource;
@class CHWebFileManager;
@class CHLinkMetaManager;

@protocol CHLogicDelegate <CHCommonLogicDelegate>
@optional
- (void)logicWatchStatusChanged;
- (void)logicNodeUpdated:(NSString *)nid;
- (void)logicNodesUpdated:(NSArray<NSString *> *)nids;
- (void)logicChannelUpdated:(NSString *)cid;
- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids;
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids;
- (void)logicMessageDeleted:(CHMessageModel *)mid;
- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids;
- (void)logicMessagesUnreadChanged:(NSNumber *)unread;
@end

@interface CHLogic : CHCommonLogic<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;
@property (nonatomic, readonly, strong) CHNSDataSource *nsDataSource;
@property (nonatomic, nullable, readonly, strong) CHLinkMetaManager *linkMetaManager;
@property (nonatomic, nullable, readonly, strong) CHWebFileManager *webFileManager;
@property (nonatomic, nullable, readonly, strong) CHWebObjectManager<UIImage *> *webImageManager;

// API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion;
- (void)importAccount:(NSString *)key completion:(nullable CHLogicBlock)completion;
- (void)bindAccount:(nullable CHSecKey *)key completion:(nullable CHLogicBlock)completion;
- (void)logoutWithCompletion:(nullable CHLogicBlock)completion;
// Nodes
- (void)updateNodeInfo:(nullable NSString*)nid completion:(nullable CHLogicBlock)completion;
- (BOOL)updateNode:(CHNodeModel *)model;
- (BOOL)deleteNode:(nullable NSString *)nid;
- (void)insertNode:(CHNodeModel *)model completion:(nullable CHLogicBlock)completion;
- (void)loadNodeWitEndpoint:(NSString *)endpoint completion:(nullable CHLogicResultBlock)completion;
- (BOOL)nodeIsConnected:(nullable NSString *)nid;
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion;
// Channels
- (BOOL)insertChannel:(NSString *)code name:(nullable NSString *)name icon:(nullable NSString *)icon;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;
// Messages
- (BOOL)deleteMessage:(nullable NSString *)mid;
- (BOOL)deleteMessages:(NSArray<NSString *> *)mids;
// Read & Unread
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (void)addReadChannel:(nullable NSString *)cid;
- (void)removeReadChannel:(nullable NSString *)cid;
// Watch
- (BOOL)hasWatch;
- (BOOL)isWatchAppInstalled;
- (BOOL)syncDataToWatch:(BOOL)focus;


@end

NS_ASSUME_NONNULL_END
