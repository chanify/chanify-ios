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
        self.tintColor = UIColor.whiteColor;
        self.clipsToBounds = YES;
        self.backgroundColor = CHTheme.shared.tintColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)setImage:(NSString *)image {
    if (![self.image isEqualToString:image?:@""]) {
        _image = image;
        UIImage *symbolImage = nil;
        UIColor *tintColor = nil;
        UIColor *backgroundColor = nil;
        NSURLComponents *components = [NSURLComponents componentsWithString:image?:@""];
        if ([components.scheme isEqualToString:@"sys"]) {
            if (components.host.length > 0) {
                symbolImage = [UIImage systemImageNamed:components.host];
            }
            for (NSURLQueryItem *item in components.queryItems) {
                if (item.value.length > 0) {
                    if ([item.name isEqualToString:@"c"]) {
                        tintColor = [UIColor colorWithRGB:(uint32_t)item.value.uint64Hex];
                    } else if ([item.name isEqualToString:@"b"]) {
                        backgroundColor = [UIColor colorWithRGB:(uint32_t)item.value.uint64Hex];
                    }
                }
            }
        }
        _iconImage = [(symbolImage?:[UIImage imageNamed:@"Channel"]) imageWithTintColor:(tintColor ?: self.tintColor)];
        self.backgroundColor = (backgroundColor ?: CHTheme.shared.tintColor);
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


@end
