//
//  CHIconConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHIconConfiguration : NSObject<UIContentConfiguration>

@property (nonatomic, readonly, strong) NSString *icon;
@property (nonatomic, readonly, strong) UIColor *tintColor;

+ (instancetype)configurationWithIcon:(NSString *)icon tintColor:(UIColor *)tintColor;


@end

NS_ASSUME_NONNULL_END
