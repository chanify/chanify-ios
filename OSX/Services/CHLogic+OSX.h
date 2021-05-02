//
//  CHLogic+OSX.h
//  OSX
//
//  Created by WizJin on 2021/5/2.
//

#import "CHLogic.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLogicDelegate <CHCommonLogicDelegate>
@optional
@end

@interface CHLogic : CHCommonLogic<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;


@end

NS_ASSUME_NONNULL_END
