//
//  CHLogic.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserModel.h"
#import "CHManager.h"
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

typedef NS_ENUM(int, CHLCode) {
    CHLCodeOK       = 200,
    CHLCodeReject   = 406,
    CHLCodeFailed   = 500,
};

typedef void (^CHLogicBlock)(CHLCode result);
typedef void (^CHLogicResultBlock)(CHLCode result, NSDictionary *data);

@protocol CHLogicDelegate <NSObject>
@optional
- (void)logicNodeUpdated:(NSString *)nid;
- (void)logicNodesUpdated:(NSArray<NSString *> *)nids;
- (void)logicChannelUpdated:(NSString *)cid;
- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids;
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids;
- (void)logicMessageDeleted:(CHMessageModel *)mid;
- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids;
- (void)logicMessagesUnreadChanged:(NSNumber *)unread;
@end

@interface CHLogic : CHManager<id<CHLogicDelegate>>

@property (nonatomic, readonly, strong) CHNSDataSource *nsDataSource;
@property (nonatomic, nullable, readonly, strong) CHUserModel *me;
@property (nonatomic, nullable, readonly, strong) CHUserDataSource *userDataSource;
@property (nonatomic, nullable, readonly, strong) CHLinkMetaManager *linkMetaManager;
@property (nonatomic, nullable, readonly, strong) CHWebFileManager *webFileManager;
@property (nonatomic, nullable, readonly, strong) CHWebObjectManager<UIImage *> *webImageManager;

+ (instancetype)shared;
- (void)launch;
- (void)active;
- (void)deactive;
- (void)resetData;
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion;
- (void)logoutWithCompletion:(nullable CHLogicBlock)completion;
- (void)importAccount:(NSString *)key completion:(nullable CHLogicBlock)completion;
- (BOOL)recivePushMessage:(NSDictionary *)userInfo;
- (void)updatePushToken:(NSData *)pushToken;
- (BOOL)deleteMessage:(nullable NSString *)mid;
- (BOOL)deleteMessages:(NSArray<NSString *> *)mids;
- (void)updateNodeInfo:(nullable NSString*)nid completion:(nullable CHLogicBlock)completion;
- (BOOL)updateNode:(CHNodeModel *)model;
- (BOOL)deleteNode:(nullable NSString *)nid;
- (void)insertNode:(CHNodeModel *)model completion:(nullable CHLogicBlock)completion;
- (void)loadNodeWitEndpoint:(NSString *)endpoint completion:(nullable CHLogicResultBlock)completion;
- (BOOL)insertChannel:(NSString *)code name:(nullable NSString *)name icon:(nullable NSString *)icon;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (void)addReadChannel:(nullable NSString *)cid;
- (void)removeReadChannel:(nullable NSString *)cid;
- (BOOL)nodeIsConnected:(nullable NSString *)nid;
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion;


@end

NS_ASSUME_NONNULL_END
