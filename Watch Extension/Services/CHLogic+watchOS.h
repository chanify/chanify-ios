//
//  CHLogic+watchOS.h
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogicBase.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLogicDelegate <NSObject>
@optional
- (void)logicUserInfoChanged:(nullable CHUserModel *)me;
@end

@interface CHLogic : CHLogicBase<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;


@end

NS_ASSUME_NONNULL_END
