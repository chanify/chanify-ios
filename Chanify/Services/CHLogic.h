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
@class CHNSDataSource;
@class CHUserDataSource;

typedef NS_ENUM(int, CHLCode) {
    CHLCodeOK       = 200,
    CHLCodeFailed   = 500,
};

typedef void (^CHLogicBlock)(CHLCode result);

@protocol CHLogicDelegate <NSObject>
@optional
- (void)logicNodeUpdated:(NSString *)nid;
- (void)logicNodesUpdated:(NSArray<NSString *> *)nids;
- (void)logicChannelUpdated:(NSString *)cid;
- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids;
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids;
@end

@interface CHLogic : CHManager<id<CHLogicDelegate>>

@property (nonatomic, nullable, readonly, strong) CHUserModel *me;
@property (nonatomic, nullable, readonly, strong) CHNSDataSource *nsDataSource;
@property (nonatomic, nullable, readonly, strong) CHUserDataSource *userDataSource;

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
- (BOOL)updateNode:(CHNodeModel *)model;
- (BOOL)deleteNode:(nullable NSString *)nid;
- (void)insertNode:(CHNodeModel *)model completion:(nullable CHLogicBlock)completion;
- (BOOL)insertChannel:(NSString *)code name:(nullable NSString *)name icon:(nullable NSString *)icon;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;


@end

NS_ASSUME_NONNULL_END
