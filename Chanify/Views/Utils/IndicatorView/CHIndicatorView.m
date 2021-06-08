//
//  CHIndicatorView.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHIndicatorView.h"
#import <QuartzCore/QuartzCore.h>
#import "CHTheme.h"

#define kCHIndicatorAnimation   "transform.rotation"

@interface CHIndicatorView ()

@property (nonatomic, readonly, strong) CAShapeLayer *circle;

@end

@implementation CHIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _gap = 0.4;
        _radius = 0;
        _speed = 1;
        
        self.alpha = 0;
#if TARGET_OS_OSX
        self.wantsLayer = YES;
        self.clipsToBounds = NO;
#endif
        CAShapeLayer *circle = [CAShapeLayer layer];
        [self.layer addSublayer:(_circle = circle)];
        circle.strokeColor = self.tintColor.CGColor;
        circle.fillColor = CHColor.clearColor.CGColor;
        circle.lineCap = kCALineCapRound;
        circle.lineWidth = 1;
    }
    return self;
}

#if TARGET_OS_OSX
#define kCHIndicatorClockwise   YES
- (BOOL)isFlipped {
    return YES;
}
#else
#define kCHIndicatorClockwise   NO
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        self.circle.strokeColor = self.tintColor.CGColor;
        [self setNeedsDisplay];
    }
    [super traitCollectionDidChange:previousTraitCollection];
}
#endif

- (void)setGap:(CGFloat)gap {
    if (_gap != gap) {
        _gap = gap;
        [self updateCircle];
    }
}

- (void)setTintColor:(CHColor *)tintColor {
    if (![self.tintColor isEqual:tintColor]) {
        [super setTintColor:tintColor];
        self.circle.strokeColor = tintColor.CGColor;
        [self setNeedsDisplay];
    }
}

- (void)setRadius:(CGFloat)radius {
    if (_radius != radius) {
        _radius = radius;
        [self updateCircle];
    }
}

- (CGFloat)lineWidth {
    return self.circle.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    if (self.circle.lineWidth != lineWidth) {
        self.circle.lineWidth = lineWidth;
        [self setNeedsDisplay];
    }
}

- (void)startAnimating {
    if ([self.circle animationForKey:@kCHIndicatorAnimation] == nil) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@kCHIndicatorAnimation];
        animation.duration = (self.speed > 0 ? 1/self.speed : 1);
        animation.fromValue = 0;
        animation.toValue = @(M_PI * 2);
        animation.repeatCount = MAXFLOAT;
        [self.circle addAnimation:animation forKey:@kCHIndicatorAnimation];

        self.alpha = 0;
        @weakify(self);
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateFastDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            @strongify(self);
            self.alpha = 1;
        } completion:nil];
    }
}

- (void)stopAnimating:(nullable dispatch_block_t)complation {
    if ([self.circle animationForKey:@kCHIndicatorAnimation] == nil) {
        self.alpha = 0;
    } else {
        [self.circle removeAllAnimations];
        @weakify(self);
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateFastDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            @strongify(self);
            self.alpha = 0;
        } completion:^(UIViewAnimatingPosition finalPosition) {
            @strongify(self);
            self.alpha = 0;
            if (complation != nil) complation();
        }];
    }
}

#pragma mark - Private Methods
- (void)updateCircle {
    self.circle.path = [CHBezierPath bezierPathWithArcCenter:CGPointZero radius:self.radius startAngle:0 endAngle:self.gap clockwise:kCHIndicatorClockwise].CGPath;
    [self setNeedsDisplay];
}


@end
