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
@property (nonatomic, assign) NSInteger tagID;

- (nullable __kindof NSView *)viewWithTagID:(NSInteger)tagID;
- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled;
- (void)setBackgroundColor:(NSColor *)color;
- (void)setNeedsDisplay;
- (void)setNeedsLayout;
- (void)setCornerRadius:(CGFloat)cornerRadius;


@end

NS_ASSUME_NONNULL_END
