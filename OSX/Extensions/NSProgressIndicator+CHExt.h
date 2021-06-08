//
//  NSProgressIndicator+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import <AppKit/NSProgressIndicator.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSProgressIndicator (CHExt)

@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithProgressViewStyle:(NSProgressIndicatorStyle)style;
- (void)setTrackTintColor:(NSColor *)trackTintColor;


@end

NS_ASSUME_NONNULL_END
