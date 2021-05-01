//
//  CHPasteboard.h
//  Chanify
//
//  Created by WizJin on 2021/4/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHPasteboard : NSObject

+ (instancetype)shared;
- (void)copyWithName:(NSString *)name value:(nullable NSString *)value;


@end

NS_ASSUME_NONNULL_END
