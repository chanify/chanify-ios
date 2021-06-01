//
//  CHBadgeView.m
//  Chanify
//
//  Created by WizJin on 2021/4/16.
//

#import "CHBadgeView.h"
#import "CHTheme.h"

@interface CHBadgeView ()

@property (nonatomic, readonly, strong) NSAttributedString *countText;
@property (nonatomic, readonly, strong) NSMutableDictionary *attributes;
#if TARGET_OS_OSX
@property (nonatomic, strong) CHColor *tintColor;
#endif

@end

@implementation CHBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.tintColor = CHTheme.shared.alertColor;
        self.alpha = 0;
#if TARGET_OS_OSX
        CHFont *font = [CHFont systemFontOfSize:8];
        self.wantsLayer = YES;
#else
        CHFont *font = [CHFont boldSystemFontOfSize:10];
        self.clipsToBounds = YES;
#endif
        _count = 0;
        _countText = nil;
        _attributes = [[NSMutableDictionary alloc] initWithDictionary:@{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: CHColor.whiteColor,
        }];
    }
    return self;
}

#if TARGET_OS_OSX
- (void)layout {
    [super layout];
    CGSize size = self.bounds.size;
    self.layer.cornerRadius = MIN(size.width, size.height) * 0.5;
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

#else
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    self.layer.cornerRadius = MIN(size.width, size.height) * 0.5;
}
#endif

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (self.countText.length > 0) {
        CGRect bounds = self.bounds;
        [self.tintColor setFill];
#if TARGET_OS_OSX
        CGContextFillRect(NSGraphicsContext.currentContext.CGContext, rect);
#else
        CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
#endif
        CGRect rc = [self.countText boundingRectWithSize:bounds.size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:nil];
        rc.size.width = ceil(rc.size.width);
        rc.size.height = ceil(rc.size.height);
        rc.origin.x = (bounds.size.width - rc.size.width) * 0.5;
        rc.origin.y = (bounds.size.height - rc.size.height) * 0.5;
        [self.countText drawInRect:rc];
    }
}

- (CHColor *)textColor {
    return [self.attributes valueForKey:NSForegroundColorAttributeName];
}

- (void)setTextColor:(CHColor *)textColor {
    if (![self.textColor isEqual:textColor]) {
        [self.attributes setValue:textColor forKey:NSForegroundColorAttributeName];
        if (self.countText.length > 0) {
            _countText = [[NSAttributedString alloc] initWithString:self.countText.string attributes:self.attributes];
        }
        [self setNeedsDisplay];
    }
}

- (void)setCount:(NSInteger)count {
    if (_count != count) {
        _count = count;
        NSString *value = @"";
        if (count <= 0) {
            self.alpha = 0;
        } else {
            self.alpha = 1;
            if (count > 99) {
                value = @"⋯";
            } else {
                value = [NSString stringWithFormat:@"%ld", (long)count];
            }
        }
        _countText = [[NSAttributedString alloc] initWithString:value attributes:self.attributes];
        [self setNeedsDisplay];
    }
}


@end
