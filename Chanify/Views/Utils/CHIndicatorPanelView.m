//
//  CHIndicatorPanelView.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHIndicatorPanelView.h"
#import <Masonry/Masonry.h>
#import "CHIndicatorView.h"
#import "CHTheme.h"

#define kCHIndicatorPanelRadius       50

@interface CHIndicatorPanelView ()

@property (nonatomic, readonly, strong) CHIndicatorView *indicatorView;

@end

@implementation CHIndicatorPanelView

- (instancetype)init {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        UIView *panel = [UIView new];
        [self addSubview:panel];
        panel.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.9];
        panel.layer.cornerRadius = 8;
        [panel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(kCHIndicatorPanelRadius*2, kCHIndicatorPanelRadius*2));
        }];

        CHIndicatorView *indicatorView = [CHIndicatorView new];
        [self addSubview:(_indicatorView = indicatorView)];
        indicatorView.tintColor = CHTheme.shared.tintColor;
        indicatorView.radius = kCHIndicatorPanelRadius * 0.7;
        indicatorView.lineWidth = 3.0;
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(panel);
        }];
    }
    return self;
}

- (void)startAnimating {
    [self.indicatorView startAnimating];
}

- (void)stopAnimating {
    [self.indicatorView stopAnimating];
}


@end
