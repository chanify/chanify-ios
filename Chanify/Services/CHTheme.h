//
//  CHTheme.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHTheme : NSObject

@property (nonatomic, readonly, strong) CHColor *tintColor;
@property (nonatomic, readonly, strong) CHColor *lightTintColor;
@property (nonatomic, readonly, strong) CHColor *labelColor;
@property (nonatomic, readonly, strong) CHColor *minorLabelColor;
@property (nonatomic, readonly, strong) CHColor *lightLabelColor;
@property (nonatomic, readonly, strong) CHColor *warnColor;
@property (nonatomic, readonly, strong) CHColor *alertColor;
@property (nonatomic, readonly, strong) CHColor *secureColor;
@property (nonatomic, readonly, strong) CHColor *backgroundColor;
@property (nonatomic, readonly, strong) CHColor *cellBackgroundColor;
@property (nonatomic, readonly, strong) CHColor *bubbleBackgroundColor;
@property (nonatomic, readonly, strong) CHColor *groupedBackgroundColor;
@property (nonatomic, readonly, strong) CHImage *clearImage;
@property (nonatomic, readonly, strong) CHImage *backImage;
@property (nonatomic, readonly, strong) CHFont *textFont;
@property (nonatomic, readonly, strong) CHFont *mediumFont;
@property (nonatomic, readonly, strong) CHFont *smallFont;
@property (nonatomic, readonly, strong) CHFont *detailFont;
@property (nonatomic, readonly, strong) CHFont *codeFont;
@property (nonatomic, readonly, strong) CHFont *messageTextFont;
@property (nonatomic, readonly, strong) CHFont *messageTitleFont;
@property (nonatomic, readonly, strong) CHFont *messageMediumFont;
@property (nonatomic, readonly, strong) CHFont *messageSmallFont;
@property (nonatomic, readonly, strong) CHFont *messageSmallDigitalFont;

#if TARGET_OS_OSX
@property (nonatomic, readonly, strong) CHColor *separatorLineColor;
@property (nonatomic, readonly, strong) CHColor *selectedCellBackgroundColor;
#else
@property (nonatomic, assign) UIUserInterfaceStyle userInterfaceStyle;
#endif

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
