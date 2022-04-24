//
//  CHPasteboard.h
//  Chanify
//
//  Created by WizJin on 2021/4/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHPasteboard : NSObject

+ (instancetype)shared;
- (nullable NSString *)stringValue;
- (void)setStringValue:(nullable NSString *)value;
- (void)copyWithName:(NSString *)name value:(nullable NSString *)value;


@end

NS_ASSUME_NONNULL_END
