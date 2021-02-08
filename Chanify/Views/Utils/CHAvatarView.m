//
//  CHAvatarView.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHAvatarView.h"
#import <AVFoundation/AVUtilities.h>
#import "CHTheme.h"

#define kCHAvatarViewInsetsScale    0.15

@interface CHAvatarView ()

@property (nonatomic, nullable, readonly, strong) UIImage *iconImage;
@property (nonatomic, readonly, assign) BOOL needIconInsets;

@end

@implementation CHAvatarView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _image = @"";
        _iconImage = nil;
        _needIconInsets = NO;
        self.clipsToBounds = YES;
        self.backgroundColor = CHTheme.shared.tintColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)setImage:(NSString *)image {
    if (![self.image isEqualToString:image]) {
        _image = image;
        _needIconInsets = NO;
        UIImage *symbol = nil;
        if ([image hasPrefix:@"sys://"]) {
            symbol = [UIImage systemImageNamed:[image substringFromIndex:6]];
        }
        if (symbol == nil) {
            symbol = [UIImage imageNamed:@"Channel"];
        }
        _iconImage = [symbol imageWithTintColor:UIColor.whiteColor];
        _needIconInsets = YES;
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
        if (self.needIconInsets) {
            rc.origin.x = rc.size.width * kCHAvatarViewInsetsScale;
            rc.size.width -= rc.origin.x * 2.0;
            rc.origin.y = rc.size.height * kCHAvatarViewInsetsScale;
            rc.size.height -= rc.origin.y * 2.0;
        }
        [self.iconImage drawInRect:AVMakeRectWithAspectRatioInsideRect(self.iconImage.size, rc)];
    }
}


@end
