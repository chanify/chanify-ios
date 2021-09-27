//
//  NSImage+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/5/3.
//

#import "NSImage+CHExt.h"
#import <objc/runtime.h>

@implementation NSImage (CHExt)

static const char *kImageColorTagKey    = "ImageColorTagKey";

+ (void)load {
    static dispatch_once_t once_token;
    dispatch_once(&once_token,  ^{
        SEL drawInRectSelector = @selector(drawInRect:);
        SEL swizzleDrawInRectSelector = @selector(swizzleDrawInRect:);
        Method originalMethod = class_getInstanceMethod(self, drawInRectSelector);
        Method extendedMethod = class_getInstanceMethod(self, swizzleDrawInRectSelector);
        method_exchangeImplementations(originalMethod, extendedMethod);
    });
}

- (nullable NSColor *)tintColor {
    return objc_getAssociatedObject(self, kImageColorTagKey);
}

- (void)setTintColor:(nullable NSColor *)color {
    objc_setAssociatedObject(self, kImageColorTagKey, color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)systemImageNamed:(NSString *)name {
    return [NSImage imageWithSystemSymbolName:name accessibilityDescription:name];
}

+ (nullable instancetype)imageWithData:(NSData *)data {
    if (data.length > 0) {
        return [[NSImage alloc] initWithData:data];
    }
    return nil;
}

- (NSImage *)imageWithTintColor:(NSColor *)color {
    NSImage *image = self;
    if (image.isTemplate) {
        NSImage *img = [image copy];
        if (img != nil) {
            img.tintColor = color;
            image = img;
        }
    }
    return image;
}

- (void)swizzleDrawInRect:(CGRect)rect {
    [self swizzleDrawInRect:rect];
    NSColor *color = self.tintColor;
    if (color != nil) {
        [color set];
        NSRectFillUsingOperation(rect, NSCompositingOperationSourceIn);
    }
}

@end
