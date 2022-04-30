//
//  CHToast.h
//  OSX
//
//  Created by WizJin on 2021/9/24.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHToast : CHLabel

+ (void)showMessage:(nullable NSString *)message color:(nullable CHColor *)color inView:(CHView *)view;


@end

NS_ASSUME_NONNULL_END
