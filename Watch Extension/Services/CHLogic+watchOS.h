//
//  CHLogic+watchOS.h
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLogicDelegate <NSObject>
@optional
- (void)logicUserInfoChanged:(nullable CHUserModel *)me;
@end

@interface CHLogic : CHCommonLogic<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;


@end

NS_ASSUME_NONNULL_END
