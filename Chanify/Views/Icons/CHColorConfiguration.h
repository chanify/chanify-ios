//
//  CHColorConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/3/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHColorConfiguration : NSObject<UIContentConfiguration>

@property (nonatomic, readonly, strong) NSString *color;
@property (nonatomic, nullable, strong) UIColor *defaultColor;

+ (instancetype)configurationWithColor:(NSString *)color;


@end

NS_ASSUME_NONNULL_END
