//
//  NSView+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView (CHExt)

@property (nonatomic, nullable, strong) NSColor *tintColor;
@property (nonatomic, assign) BOOL chClipsToBounds;
@property (nonatomic, assign) CGFloat alpha;

- (void)setBackgroundColor:(NSColor *)color;
- (void)setNeedsDisplay;


@end

NS_ASSUME_NONNULL_END
