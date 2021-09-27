//
//  CHIconConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHIconConfiguration : NSObject<CHContentConfiguration>

@property (nonatomic, readonly, strong) NSString *icon;

+ (instancetype)configurationWithIcon:(NSString *)icon;


@end

NS_ASSUME_NONNULL_END
