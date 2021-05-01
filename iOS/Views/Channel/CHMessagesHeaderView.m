//
//  CHMessagesHeaderView.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessagesHeaderView.h"
#import <Masonry/Masonry.h>
#import "CHIndicatorView.h"
#import "CHTheme.h"

@interface CHMessagesHeaderView ()

@property (nonatomic, readonly, strong) CHIndicatorView *indicatorView;
@property (nonatomic, readonly, strong) UILabel *tipLabel;

@end

@implementation CHMessagesHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _status = CHMessagesHeaderStatusNormal;
        
        CHTheme *theme = CHTheme.shared;
        
        CHIndicatorView *indicatorView = [CHIndicatorView new];
        [self addSubview:(_indicatorView = indicatorView)];
        indicatorView.tintColor = theme.labelColor;
        indicatorView.lineWidth = 2;
        indicatorView.radius = 8;
        indicatorView.speed = 1.8;
        indicatorView.gap = 0.8;
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];

        UILabel *tipLabel = [UILabel new];
        [self addSubview:(_tipLabel = tipLabel)];
        tipLabel.text = [NSString stringWithFormat:@"────  %@  ────", @"NoMore".localized];
        tipLabel.font = [UIFont italicSystemFontOfSize:12];
        tipLabel.textColor = theme.minorLabelColor;
        tipLabel.textAlignment = NSTextAlignmentCenter;
        tipLabel.numberOfLines = 1;
        tipLabel.alpha = 0;
        [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
    }
    return self;
}

- (void)setStatus:(CHMessagesHeaderStatus)status {
    if (self.status != status) {
        _status = status;
        switch (self.status) {
            case CHMessagesHeaderStatusNormal:
                self.tipLabel.alpha = 0;
                [self.indicatorView stopAnimating:nil];
                break;
            case CHMessagesHeaderStatusLoading:
                self.tipLabel.alpha = 0;
                [self.indicatorView startAnimating];
                break;
            case CHMessagesHeaderStatusFinish:
                self.tipLabel.alpha = 1;
                [self.indicatorView stopAnimating:nil];
                break;
        }
    }
}


@end
