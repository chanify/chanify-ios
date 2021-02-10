//
//  CHChannelConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>
#import "CHChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHChannelConfiguration : NSObject<UIContentConfiguration>

@property (nonatomic, readonly, strong) CHChannelModel *model;

+ (instancetype)cellConfiguration:(CHChannelModel *)model;


@end


NS_ASSUME_NONNULL_END
