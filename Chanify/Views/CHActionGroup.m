//
//  CHActionGroup.m
//  iOS
//
//  Created by WizJin on 2021/5/13.
//

#import "CHActionGroup.h"
#import "CHTheme.h"

#define kCHActionItemMaxN       4
#define kCHActionItemViewTag    1000
#define kCHActionItemLineTag    2000

@interface CHActionGroup ()

@property (nonatomic, readonly, strong) CHView *lineView;

@end

@implementation CHActionGroup

+ (CGFloat)defaultHeight {
    return 46;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _lineWidth = 1.0/CHScreen.mainScreen.scale;

        CHTheme *theme = CHTheme.shared;
        CHColor *btnTitleColor = [theme.tintColor colorWithAlphaComponent:0.7];
        CHFont *btnTitleFont = [CHFont systemFontOfSize:16];
        CHColor *bkgColor = [CHColor colorWithWhite:0 alpha:0.01];

        CHView *lineView = [CHView new];
        [self addSubview:(_lineView = lineView)];
        lineView.backgroundColor = theme.lightLabelColor;
        for (int i = 0; i < kCHActionItemMaxN; i++) {
            CHButton *btn = [CHButton button];
            [self addSubview:btn];
            [btn addTarget:self action:@selector(doAction:)];
            btn.titleTintColor = theme.tintColor;
            btn.titleSelectColor = btnTitleColor;
            btn.titleFont = btnTitleFont;
            btn.backgroundColor = bkgColor;
            btn.tagID = kCHActionItemViewTag + i;
            btn.hidden = YES;
            if (i > 0) {
                CHLineView *line = [CHLineView new];
                [self addSubview:line];
                line.tagID = kCHActionItemLineTag + i;
                line.backgroundColor = theme.lightLabelColor;
                line.hidden = YES;
            }
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    self.lineView.frame = CGRectMake(0, 0, size.width, self.lineWidth);
    NSUInteger n = self.actions.count;
    CGFloat width = (n > 0 ? size.width/n : 0);
    for (int i = 0; i < n; i++) {
        CHButton *btn = [self viewWithTag:kCHActionItemViewTag + i];
        btn.frame = CGRectMake(width * i, self.lineWidth, width, size.height - self.lineWidth);
        CHView *line = [self viewWithTag:kCHActionItemLineTag + i];
        line.frame = CGRectMake(width * i, self.lineWidth, self.lineWidth, size.height - self.lineWidth);
    }
}

- (void)setActions:(NSArray<CHActionItemModel *> *)actions {
    if (actions.count > kCHActionItemMaxN) actions = [actions subarrayWithRange:NSMakeRange(0, 4)];
    if (![_actions isEqualToArray:actions]) {
        _actions = actions;
        for (int i = 0; i < kCHActionItemMaxN; i++) {
            CHButton *btn = [self viewWithTag:kCHActionItemViewTag + i];
            if (i >= actions.count) {
                btn.hidden = YES;
            } else {
                btn.hidden = NO;
                CHActionItemModel *model = [actions objectAtIndex:i];
                btn.normalTitle = model.name;
            }
            CHView *line = [self viewWithTag:kCHActionItemLineTag + i];
            line.hidden = btn.hidden;
        }
        [self setNeedsLayout];
    }
}

#pragma mark - Action Methods
- (void)doAction:(CHButton *)button {
    [self.delegate actionGroupSelected:[self.actions objectAtIndex:button.tag - kCHActionItemViewTag]];
}


@end
