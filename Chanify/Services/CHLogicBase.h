//
//  CHLogicBase.h
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
    CHLCodeReject   = 406,
    CHLCodeFailed   = 500,
};

typedef void (^CHLogicBlock)(CHLCode result);
typedef void (^CHLogicResultBlock)(CHLCode result, NSDictionary *data);

@protocol CHLogicBaseDelegate <NSObject>
@optional
- (void)logicNodeUpdated:(NSString *)nid;
- (void)logicNodesUpdated:(NSArray<NSString *> *)nids;
- (void)logicChannelUpdated:(NSString *)cid;
- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids;
- (void)logicBlockedTokenChanged;
@end

@interface CHLogicBase<T> : CHManager<T>

@property (nonatomic, readonly, strong) NSURL *baseURL;
@property (nonatomic, readonly, strong) CHNSDataSource *nsDataSource;
@property (nonatomic, nullable, readonly, strong) CHUserModel *me;
@property (nonatomic, nullable, readonly, strong) CHUserDataSource *userDataSource;

- (instancetype)initWithAppGroup:(NSString *)appGroup;
- (void)launch;
- (void)close;
- (void)active;
- (void)deactive;
- (void)resetData;
- (void)reloadUserDB:(BOOL)force;
- (nullable NSURL *)dbPath:(nullable NSString *)uid;
- (void)updatePushToken:(NSData *)pushToken;
- (void)updatePushToken:(NSData *)pushToken node:(CHNodeModel *)node completion:(nullable CHLogicBlock)completion;
- (void)receiveRemoteNotification:(NSDictionary *)userInfo;
- (void)updateUserModel:(nullable CHUserModel *)me;
- (void)sendCmd:(NSString *)cmd user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion;
- (void)sendToEndpoint:(NSURL *)endpoint cmd:(NSString *)cmd device:(BOOL)device seckey:(nullable CHSecKey *)seckey user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
// API
- (void)bindAccount:(nullable CHSecKey *)key completion:(nullable CHLogicBlock)completion;
- (void)importAccount:(NSString *)key completion:(nullable CHLogicBlock)completion;
- (void)logoutWithCompletion:(nullable CHLogicBlock)completion;
- (void)doLogin:(CHUserModel *)user key:(NSData *)key;
- (void)doLogout;
// Nodes
- (void)loadNodeWitEndpoint:(NSString *)endpoint completion:(nullable CHLogicResultBlock)completion;
- (void)updateNodeInfo:(nullable NSString*)nid completion:(nullable CHLogicBlock)completion;
- (void)insertNode:(CHNodeModel *)model completion:(nullable CHLogicBlock)completion;
- (BOOL)deleteNode:(nullable NSString *)nid;
- (BOOL)updateNode:(CHNodeModel *)model;
- (nullable CHNodeModel *)nodeModelWithNID:(nullable NSString *)nid;
- (BOOL)nodeIsConnected:(nullable NSString *)nid;
// Channels
- (BOOL)insertChannel:(CHChannelModel *)model;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;
// Blocklist
- (void)upsertBlockedToken:(NSString *)token;
- (void)removeBlockedTokens:(NSArray<NSString *> *)tokens;
- (NSArray<NSString *> *)blockedTokens;
// Subclass
- (void)sendBlockTokenChanged;


@end

NS_ASSUME_NONNULL_END
