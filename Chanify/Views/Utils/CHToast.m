//
//  CHToast.m
//  OSX
//
//  Created by WizJin on 2021/9/24.
//

#import "CHToast.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@implementation CHToast

#if TARGET_OS_OSX

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.wantsLayer = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor setFill];
    CGContextFillRect(NSGraphicsContext.currentContext.CGContext, self.bounds);
    [super drawRect:dirtyRect];
}

#endif

+ (void)showMessage:(nullable NSString *)message inView:(CHView *)view {
    if (message.length > 0) {
        dispatch_main_async(^{
            showToast(view, message);
        });
    }
}

- (void)open:(NSTimeInterval)delay {
    @weakify(self);
    [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateFastDuration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
        @strongify(self);
        self.alpha = 1;
    } completion:nil];
}

- (void)close:(NSTimeInterval)delay {
    @weakify(self);
    [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateFastDuration delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
        @strongify(self);
        self.alpha = 0;
    } completion:^(UIViewAnimatingPosition finalPosition) {
        @strongify(self);
        [self removeFromSuperview];
    }];
}

static inline void showToast(CHView *view, NSString *message) {
    static const CGFloat radius = 14.0;
    NSTimeInterval delay = 0;
    static __weak CHToast *lastToast = nil;
    if (lastToast != nil) {
        delay += 0.2;
        [lastToast close:0];
        lastToast = nil;
    }
    
    CHToast *toast = [CHToast new];
    [view addSubview:(lastToast = toast)];
    toast.text = message;
    toast.alpha = 0;
    toast.numberOfLines = 1;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = CHTheme.shared.mediumFont;
    toast.textColor = CHColor.whiteColor;
    toast.backgroundColor = [CHColor colorWithWhite:0.3 alpha:0.8];
    toast.layer.cornerRadius = radius;
    toast.clipsToBounds = YES;

    CGSize size = [toast sizeThatFits:CGSizeMake(view.bounds.size.width * 0.8, radius * 2)];
    size.height = radius * 2;
    size.width += floor(radius * 2);
    size.width = fmax(size.width, radius * 4);
    
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(view.mas_bottom).offset(-60);
        make.centerX.equalTo(view);
        make.size.mas_equalTo(size);
    }];
    [toast open:delay];
    dispatch_main_after(2.0, ^{
        [toast close:0];
    });
}


@end
