//
//  CHFormCodeItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormCodeItem : CHFormValueItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title code:(nullable id)code;


@end

NS_ASSUME_NONNULL_END
