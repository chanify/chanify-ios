//
//  CHFormButtonItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormButtonItem : CHFormItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title action:(CHFormItemActionBlock)action;


@end

NS_ASSUME_NONNULL_END
