//
//  NSButton+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSButton (CHExt)

+ (instancetype)systemButtonWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action;
+ (instancetype)button;
- (void)setTitleFont:(NSFont *)font;
- (void)setTitleTintColor:(NSColor *)color;
- (void)setTitleSelectColor:(NSColor *)color;
- (void)setNormalTitle:(NSString *)normalTitle;
- (void)addTarget:(nullable id)target action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
