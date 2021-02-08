//
//  CHTextMsgCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMsgCellConfiguration.h"
#import "CHMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHTextMsgCellConfiguration : CHMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model;


@end

NS_ASSUME_NONNULL_END
