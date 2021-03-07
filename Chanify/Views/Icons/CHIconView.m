//
//  CHIconView.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHIconView.h"
#import <AVFoundation/AVUtilities.h>
#import "CHTheme.h"

@interface CHIconView ()

@property (nonatomic, nullable, readonly, strong) UIImage *iconImage;

@end

@implementation CHIconView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _image = nil;
        _iconImage = nil;
        _tintColor = UIColor.whiteColor;
        self.clipsToBounds = YES;
        self.backgroundColor = CHTheme.shared.tintColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)setImage:(NSString *)image {
    if (![self.image isEqualToString:image?:@""]) {
        _image = image;
        _iconImage = [self.symbolImage imageWithTintColor:self.tintColor];
        [self setNeedsDisplay];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    if (![_tintColor isEqual:tintColor]) {
        _tintColor = tintColor;
        _iconImage = [self.symbolImage imageWithTintColor:self.tintColor];
        [self setNeedsDisplay];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize sz = self.bounds.size;
    self.layer.cornerRadius = MAX(4.0, MIN(sz.width, sz.height) * 0.2);
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (self.iconImage != nil) {
        CGRect rc = self.bounds;
        rc.origin.x = rc.size.width * 0.15;
        rc.size.width -= rc.origin.x * 2.0;
        rc.origin.y = rc.size.height * 0.15;
        rc.size.height -= rc.origin.y * 2.0;
        [self.iconImage drawInRect:AVMakeRectWithAspectRatioInsideRect(self.iconImage.size, rc)];
    }
}

#pragma mark - Private Methods
- (UIImage *)symbolImage {
    UIImage *symbolImage = nil;
    if (self.image.length > 0) {
        symbolImage = [UIImage systemImageNamed:self.image];
    }
    if (symbolImage == nil) {
        symbolImage = [UIImage imageNamed:@"Channel"];
    }
    return symbolImage;
}


@end
