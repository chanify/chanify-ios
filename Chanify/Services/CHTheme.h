//
//  CHTheme.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHTheme : NSObject

@property (nonatomic, readonly, strong) UIColor *tintColor;
@property (nonatomic, readonly, strong) UIColor *labelColor;
@property (nonatomic, readonly, strong) UIColor *minorLabelColor;
@property (nonatomic, readonly, strong) UIColor *lightLabelColor;
@property (nonatomic, readonly, strong) UIColor *warnColor;
@property (nonatomic, readonly, strong) UIColor *alertColor;
@property (nonatomic, readonly, strong) UIColor *secureColor;
@property (nonatomic, readonly, strong) UIColor *backgroundColor;
@property (nonatomic, readonly, strong) UIColor *bubbleBackgroundColor;
@property (nonatomic, readonly, strong) UIColor *groupedBackgroundColor;
@property (nonatomic, readonly, strong) UIImage *clearImage;
@property (nonatomic, readonly, strong) UIImage *backImage;
@property (nonatomic, assign) UIUserInterfaceStyle userInterfaceStyle;

+ (instancetype)shared;


@end

NS_ASSUME_NONNULL_END
