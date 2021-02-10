//
//  CHLogic.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserModel.h"
#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHNSDataSource;
@class CHUserDataSource;

typedef NS_ENUM(int, CHLCode) {
    CHLCodeOK       = 200,
    CHLCodeFailed   = 500,
};

typedef void (^CHLogicBlock)(CHLCode result);

@protocol CHLogicDelegate <NSObject>
@optional
- (void)logicMessageUpdated:(NSArray<NSNumber *> *)mids;
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


@end

NS_ASSUME_NONNULL_END
