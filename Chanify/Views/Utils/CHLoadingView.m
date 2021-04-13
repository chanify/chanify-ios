//
//  CHLoadingView.m
//  Chanify
//
//  Created by WizJin on 2021/4/13.
//

#import "CHLoadingView.h"
#import "CHTheme.h"

#define kCHLoadingLineWidth 2.0

@interface CHLoadingView () <CAAnimationDelegate>

@property (nonatomic, readonly, strong) UIButton *reloadButton;
@property (nonatomic, readonly, strong) CAShapeLayer *loadingLayer;

@end

@implementation CHLoadingView

+ (instancetype)loadingViewWithTarget:(nullable id)target action:(nullable SEL)action {
    return [[self.class alloc] initWithTarget:target action:action];
}

- (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action {
    if (self = [super init]) {
        _progress = 0;

        CHTheme *theme = CHTheme.shared;
        self.clipsToBounds = YES;
        self.backgroundColor = UIColor.clearColor;
        self.layer.borderColor = theme.tintColor.CGColor;
        self.layer.borderWidth = kCHLoadingLineWidth;
        
        CAShapeLayer *loadingLayer = [CAShapeLayer layer];
        [self.layer addSublayer:(_loadingLayer = loadingLayer)];
        loadingLayer.backgroundColor = UIColor.clearColor.CGColor;
        loadingLayer.fillColor = loadingLayer.backgroundColor;
        loadingLayer.strokeColor = theme.lightTintColor.CGColor;
        loadingLayer.lineCap = kCALineCapButt;
        self.loadingLayer.lineWidth = 0;
        loadingLayer.strokeEnd = 0;
        
        UIButton *reloadButton = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath"] target:target action:action];
        [self addSubview:(_reloadButton = reloadButton)];
        reloadButton.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    self.reloadButton.frame = bounds;
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) * 0.5;
    self.layer.cornerRadius = radius;
    self.loadingLayer.position = CGPointMake(bounds.size.width*0.5, bounds.size.height*0.5);
    radius -= kCHLoadingLineWidth * 2;
    if (self.loadingLayer.lineWidth != radius) {
        self.loadingLayer.lineWidth = radius;
        self.loadingLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointZero radius:radius*0.5 startAngle:-M_PI_2 endAngle:-M_PI_2 + (M_PI * 2) clockwise:1].CGPath;
    }
}

- (void)setProgress:(CGFloat)progress {
    if (_progress != progress) {
        _progress = progress;
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.fromValue = nil;
        animation.toValue = @(progress);
        animation.duration = kCHAnimateSlowDuration;
        animation.duration = kCHAnimateSlowDuration;
        animation.delegate = self;
        [self.loadingLayer addAnimation:animation forKey:nil];
    }
}

- (void)reset {
    [self.loadingLayer removeAllAnimations];
    self.loadingLayer.strokeEnd = 0;
    self.reloadButton.hidden = YES;
    [self setNeedsDisplay];
}

- (void)switchToFailed {
    [self.loadingLayer removeAllAnimations];
    self.loadingLayer.strokeEnd = 0;
    self.reloadButton.hidden = NO;
    [self setNeedsDisplay];
}

- (void)stop:(BOOL)animated {
    if (animated && self.progress != 1) {
        self.progress = 1;
    } else {
        [self.loadingLayer removeAllAnimations];
        [self removeFromSuperview];
    }
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    CABasicAnimation *animation = (CABasicAnimation *)anim;
    if ([animation.toValue doubleValue] >= 1.0) {
        @weakify(self);
        dispatch_main_after(kCHAnimateMediumDuration, ^{
            @strongify(self);
            [self stop:NO];
        });
    }
}


@end
