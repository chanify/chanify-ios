//
//  CHGotoBottomButton.m
//  iOS
//
//  Created by wizjin on 2023/8/5.
//

#import "CHGotoBottomButton.h"
#import <Masonry/Masonry.h>
#import "CHBadgeView.h"
#import "CHTheme.h"

@interface CHGotoBottomButton ()

@property (nonatomic, strong, readonly) UITapGestureRecognizer *gestureRecognizer;
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) CHBadgeView *badgeView;
@property (nonatomic, weak, readonly) id target;
@property (nonatomic, assign, readonly) SEL action;

@end


@implementation CHGotoBottomButton

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super init]) {
        CHTheme *theme = CHTheme.shared;
        _enabled = NO;
        _hasUnread = NO;
        _target = target;
        _action = action;
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down.circle.fill"]];
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        iconView.tintColor = theme.labelColor;
        iconView.alpha = 0;
        [self addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        CHBadgeView *badgeView = [[CHBadgeView alloc] initWithFont:[UIFont boldSystemFontOfSize:8]];
        [self addSubview:(_badgeView = badgeView)];
        badgeView.backgroundColor = theme.alertColor;
        badgeView.textColor = theme.labelColor;
        [badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(12, 12));
            make.top.right.equalTo(self);
        }];
        
        self.userInteractionEnabled = YES;
        _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionClick:)];
        [self addGestureRecognizer:self.gestureRecognizer];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    if (self.enabled != enabled) {
        _enabled = enabled;
        self.alpha = enabled ? 1 : 0;
        if (!enabled) {
            self.hasUnread = NO;
        }
        @weakify(self);
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateMediumDuration delay:0 options:0 animations:^{
            @strongify(self);
            self.iconView.alpha = (enabled ? 0.7 : 0);
        } completion:nil];
    }
}

- (void)setHasUnread:(BOOL)hasUnread {
    _hasUnread = hasUnread;
    if (hasUnread) {
        self.badgeView.count += 1;
    } else {
        self.badgeView.count = 0;
    }
}

#pragma mark - Action methods
- (void)actionClick:(id)sender {
    if (self.enabled && self.target) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:sender];
#pragma clang diagnostic pop
    }
}

@end
