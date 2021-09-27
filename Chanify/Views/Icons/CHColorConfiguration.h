//
//  CHColorConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/3/8.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHColorConfiguration : NSObject<CHContentConfiguration>

@property (nonatomic, readonly, strong) NSString *color;
@property (nonatomic, nullable, strong) CHColor *defaultColor;

+ (instancetype)configurationWithColor:(NSString *)color;


@end

NS_ASSUME_NONNULL_END
