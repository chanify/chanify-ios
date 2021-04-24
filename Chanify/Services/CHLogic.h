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
@end

@interface CHCommonLogic<T> : CHManager<T>

@property (nonatomic, readonly, strong) NSURL *baseURL;
@property (nonatomic, nullable, readonly, strong) CHUserModel *me;
@property (nonatomic, nullable, readonly, strong) CHUserDataSource *userDataSource;

- (void)launch;
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
- (void)doLogin:(CHUserModel *)user key:(NSData *)key;
// Nodes
- (void)insertNode:(CHNodeModel *)model completion:(nullable CHLogicBlock)completion;
- (void)updateNodeKey:(NSData *)key uid:(NSString *)uid;
- (BOOL)nodeIsConnected:(nullable NSString *)nid;


@end

NS_ASSUME_NONNULL_END
