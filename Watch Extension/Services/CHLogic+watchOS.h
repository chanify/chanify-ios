//
//  CHLogic+watchOS.h
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHUserModel.h"
#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLogicDelegate <NSObject>
@optional
- (void)logicUserInfoChanged:(nullable CHUserModel *)me;
@end

@interface CHLogic : CHManager<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;
@property (nonatomic, nullable, readonly, strong) CHUserModel *me;


@end

NS_ASSUME_NONNULL_END
