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

static const char *kTagTagKey       = "TagTagKey";
static const char *kTintColorTagKey = "TintColorTagKey";

@dynamic chClipsToBounds;
@dynamic tintColor;

- (NSInteger)tagID {
    NSNumber *t = objc_getAssociatedObject(self, kTagTagKey);
    if (t != nil) {
        return t.integerValue;
    }
    return -1;
}

- (void)setTagID:(NSInteger)tagID {
    objc_setAssociatedObject(self, kTagTagKey, @(tagID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSColor *)tintColor {
    return objc_getAssociatedObject(self, kTintColorTagKey);
}

- (void)setTintColor:(NSColor *)tintColor {
    objc_setAssociatedObject(self, kTintColorTagKey, tintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable __kindof NSView *)viewWithTagID:(NSInteger)tagID {
    for (NSView *view in self.subviews) {
        if (view.tagID == tagID) {
            return view;
        }
    }
    return nil;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
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

- (void)setNeedsLayout {
    self.needsLayout = YES;
}

- (CGFloat)alpha {
    return self.alphaValue;
}

- (void)setAlpha:(CGFloat)alpha {
    self.alphaValue = alpha;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = cornerRadius;
}


@end
