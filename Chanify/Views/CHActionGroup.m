//
//  CHActionGroup.m
//  iOS
//
//  Created by WizJin on 2021/5/13.
//

#import "CHActionGroup.h"

#define kCHActionItemMaxN       4
#define kCHActionItemViewTag    1000
#define kCHActionItemLineTag    2000

@interface CHActionGroup ()

@property (nonatomic, readonly, strong) UIView *lineView;

@end

@implementation CHActionGroup

+ (CGFloat)defaultHeight {
    return 46;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *lightLabelColor = UIColor.tertiaryLabelColor;
        UIColor *tintColor = [UIColor colorNamed:@"AccentColor"];
        UIColor *btnTitleColor = [tintColor colorWithAlphaComponent:0.7];
        UIFont *btnTitleFont = [UIFont systemFontOfSize:16];
        UIColor *bkgColor = [UIColor colorWithWhite:0 alpha:0.01];
        
        UIView *lineView = [UIView new];
        [self addSubview:(_lineView = lineView)];
        lineView.backgroundColor = lightLabelColor;
        for (int i = 0; i < kCHActionItemMaxN; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self addSubview:btn];
            [btn addTarget:self action:@selector(doAction:) forControlEvents:UIControlEventTouchUpInside];
            [btn setTitleColor:tintColor forState:UIControlStateNormal];
            [btn setTitleColor:btnTitleColor forState:UIControlStateSelected];
            [btn setTitleColor:btnTitleColor forState:UIControlStateHighlighted];
            btn.titleLabel.font = btnTitleFont;
            btn.backgroundColor = bkgColor;
            btn.tag = kCHActionItemViewTag + i;
            btn.hidden = YES;
            if (i > 0) {
                UIView *line = [UIView new];
                [self addSubview:line];
                line.tag = kCHActionItemLineTag + i;
                line.backgroundColor = lightLabelColor;
                line.hidden = YES;
            }
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    CGFloat pt = 1.0/UIScreen.mainScreen.scale;
    self.lineView.frame = CGRectMake(0, 0, size.width, pt);
    NSUInteger n = self.actions.count;
    CGFloat width = (n > 0 ? size.width/n : 0);
    for (int i = 0; i < n; i++) {
        UIButton *btn = [self viewWithTag:kCHActionItemViewTag + i];
        btn.frame = CGRectMake(width * i, pt, width, size.height - pt);
        UIView *line = [self viewWithTag:kCHActionItemLineTag + i];
        line.frame = CGRectMake(width * i, pt, pt, size.height - pt);
    }
}

- (void)setActions:(NSArray<CHActionItemModel *> *)actions {
    if (actions.count > kCHActionItemMaxN) actions = [actions subarrayWithRange:NSMakeRange(0, 4)];
    if (![_actions isEqualToArray:actions]) {
        _actions = actions;
        for (int i = 0; i < kCHActionItemMaxN; i++) {
            UIButton *btn = [self viewWithTag:kCHActionItemViewTag + i];
            if (i >= actions.count) {
                btn.hidden = YES;
            } else {
                btn.hidden = NO;
                CHActionItemModel *model = [actions objectAtIndex:i];
                [btn setTitle:model.name forState:UIControlStateNormal];
            }
            UIView *line = [self viewWithTag:kCHActionItemLineTag + i];
            line.hidden = btn.hidden;
        }
        [self setNeedsLayout];
    }
}

#pragma mark - Action Methods
- (void)doAction:(UIButton *)button {
    [self.delegate actionGroupSelected:[self.actions objectAtIndex:button.tag - kCHActionItemViewTag]];
}


@end
