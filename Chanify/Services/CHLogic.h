//
//  CHLogic.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserModel.h"
#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHNodeModel;
@class CHChannelModel;
@class CHMessageModel;
@class CHNSDataSource;
@class CHUserDataSource;

typedef NS_ENUM(int, CHLCode) {
    CHLCodeOK       = 200,
    CHLCodeReject   = 406,
    CHLCodeFailed   = 500,
};

typedef void (^CHLogicBlock)(CHLCode result);
typedef void (^CHLogicResultBlock)(CHLCode result, NSDictionary *data);

@protocol CHCommonLogicDelegate <NSObject>
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

@interface CHCommonLogic<T> : CHManager<T>

@property (nonatomic, readonly, strong) CHNSDataSource *nsDataSource;
@property (nonatomic, nullable, readonly, strong) CHUserModel *me;
@property (nonatomic, nullable, readonly, strong) CHUserDataSource *userDataSource;

- (void)active;
- (void)deactive;
- (void)resetData;
- (void)logoutWithCompletion:(nullable CHLogicBlock)completion;
- (void)importAccount:(NSString *)key completion:(nullable CHLogicBlock)completion;
- (void)bindAccount:(nullable CHSecKey *)key completion:(nullable CHLogicBlock)completion;
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
- (BOOL)nodeIsConnected:(nullable NSString *)nid;
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion;
// Subclass methods
- (void)reloadDB:(NSURL *)dbpath uid:(nullable NSString *)uid;
- (void)reloadUserDB;
- (void)doLogin:(CHUserModel *)user key:(NSData *)key;
- (void)doLogout;
- (BOOL)isReadChannel:(NSString *)cid;


@end

NS_ASSUME_NONNULL_END
