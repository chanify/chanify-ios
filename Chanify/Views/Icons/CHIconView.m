//
//  CHIconView.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHIconView.h"
#import <AVFoundation/AVUtilities.h>
#import "CHIconView.h"
#import "CHTheme.h"

@interface CHIconView ()

@property (nonatomic, nullable, readonly, strong) CHImage *iconImage;

@end

@implementation CHIconView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _image = nil;
        _iconImage = nil;
        self.tintColor = CHColor.whiteColor;
        self.backgroundColor = CHTheme.shared.tintColor;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setImage:(NSString *)image {
    if (![self.image isEqualToString:image?:@""]) {
        _image = image;
        CHImage *symbolImage = nil;
        CHColor *tintColor = nil;
        CHColor *backgroundColor = nil;
        NSURLComponents *components = [NSURLComponents componentsWithString:image?:@""];
        if ([components.scheme isEqualToString:@"sys"]) {
            if (components.host.length > 0) {
                symbolImage = [CHImage systemImageNamed:components.host];
            }
            for (NSURLQueryItem *item in components.queryItems) {
                if (item.value.length > 0) {
                    if ([item.name isEqualToString:@"c"]) {
                        tintColor = [CHColor colorWithRGB:(uint32_t)item.value.uint64Hex];
                    } else if ([item.name isEqualToString:@"b"]) {
                        backgroundColor = [CHColor colorWithRGB:(uint32_t)item.value.uint64Hex];
                    }
                }
            }
        }
        _iconImage = [(symbolImage?:[CHImage imageNamed:@"Channel"]) imageWithTintColor:(tintColor ?: self.tintColor)];
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
        [self.iconImage drawInRect:AVMakeRectWithAspectRatioInsideRect(self.iconImage.size, fixDrawRect(self.bounds))];
    }
}

- (CHImage *)saveImage {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.backgroundColor setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), self.bounds);
    if (self.iconImage != nil) {
        [self.iconImage drawInRect:AVMakeRectWithAspectRatioInsideRect(self.iconImage.size, fixDrawRect(self.bounds))];
    }
    CHImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static inline CGRect fixDrawRect(CGRect rc) {
    rc.origin.x = rc.size.width * 0.15;
    rc.size.width -= rc.origin.x * 2.0;
    rc.origin.y = rc.size.height * 0.15;
    rc.size.height -= rc.origin.y * 2.0;
    return rc;
}


@end
