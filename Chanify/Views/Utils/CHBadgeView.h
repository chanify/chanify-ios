//
//  CHBadgeView.h
//  Chanify
//
//  Created by WizJin on 2021/4/16.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHBadgeView : CHView

@property (nonatomic, strong) CHColor *textColor;
@property (nonatomic, assign) NSInteger count;

- (instancetype)initWithFont:(CHFont *)font;


@end

NS_ASSUME_NONNULL_END
