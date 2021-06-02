//
//  NSView+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "NSView+CHExt.h"
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@implementation NSView (CHExt)

static const char *kTintColorTagKey = "TintColorTagKey";

@dynamic chClipsToBounds;
@dynamic tintColor;

- (nullable NSColor *)tintColor {
    return objc_getAssociatedObject(self, kTintColorTagKey);
}

- (void)setTintColor:(NSColor *)tintColor {
    objc_setAssociatedObject(self, kTintColorTagKey, tintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setBackgroundColor:(NSColor *)color {
    self.wantsLayer = YES;
    self.layer.backgroundColor = color.CGColor;
}

- (void)setChClipsToBounds:(BOOL)val {
    self.wantsLayer = YES;
    self.layer.masksToBounds = val;
}

- (BOOL)chClipsToBounds {
    return self.layer.masksToBounds;
}

- (void)setNeedsDisplay {
    self.needsDisplay = YES;
}

- (CGFloat)alpha {
    return self.alphaValue;
}

- (void)setAlpha:(CGFloat)alpha {
    self.alphaValue = alpha;
}


@end
