//
//  NSImageView+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSImageView+CHExt.h"

@implementation NSImageView (CHExt)

- (instancetype)initWithImage:(NSImage *)image {
    if (self = [super initWithFrame:CGRectZero]) {
        self.image = image;
    }
    return self;
}

- (void)setContentMode:(NSInteger)contentMode {
    self.imageScaling = contentMode;
}

- (void)setTintColor:(NSColor *)tintColor {
    [self setContentTintColor:tintColor];
}

- (nullable NSColor *)tintColor {
    return self.contentTintColor;
}


@end
