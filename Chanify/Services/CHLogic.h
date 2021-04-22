//
//  CHLogic.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserModel.h"
#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, CHLCode) {
    CHLCodeOK       = 200,
    CHLCodeReject   = 406,
    CHLCodeFailed   = 500,
};

typedef void (^CHLogicBlock)(CHLCode result);
typedef void (^CHLogicResultBlock)(CHLCode result, NSDictionary *data);

@protocol CHCommonLogicDelegate <NSObject>
@optional
@end

@interface CHCommonLogic<T> : CHManager<T>

@property (nonatomic, readonly, strong) NSURL *baseURL;
@property (nonatomic, readonly, strong) NSData *pushToken;
@property (nonatomic, nullable, readonly, strong) CHUserModel *me;

- (void)active;
- (void)deactive;
- (void)updatePushToken:(NSData *)pushToken;
- (void)updateUserModel:(nullable CHUserModel *)me;
- (void)sendCmd:(NSString *)cmd user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion;
- (void)sendToEndpoint:(NSURL *)endpoint cmd:(NSString *)cmd device:(BOOL)device seckey:(nullable CHSecKey *)seckey user:(CHUserModel *)user parameters:(NSDictionary *)parameters completion:(nullable void (^)(NSURLResponse *response, NSDictionary *result, NSError *error))completion;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;


@end

NS_ASSUME_NONNULL_END
