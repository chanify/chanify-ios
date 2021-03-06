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
@property (nonatomic, readonly, strong) CHFont *messageTextFont;
@property (nonatomic, readonly, strong) CHFont *messageTitleFont;

#if TARGET_OS_OSX
@property (nonatomic, readonly, strong) CHColor *selectedCellBackgroundColor;
#else
@property (nonatomic, assign) UIUserInterfaceStyle userInterfaceStyle API_AVAILABLE(ios(13.0));
#endif

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
