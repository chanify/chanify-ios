//
//  NSException+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSException.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSException (CHExt)

+ (instancetype)exceptionWithReason:(nullable NSString *)reason;


@end

NS_ASSUME_NONNULL_END
