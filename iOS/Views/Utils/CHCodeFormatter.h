//
//  CHCodeFormatter.h
//  Chanify
//
//  Created by WizJin on 2021/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHCodeFormatter : NSObject

+ (instancetype)shared;
- (nullable NSString *)formatCode:(NSString *)val length:(NSUInteger)length;


@end

NS_ASSUME_NONNULL_END
