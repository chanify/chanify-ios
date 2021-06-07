//
//  CHBubbleMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHBubbleMsgCellConfiguration.h"
#import "CHTheme.h"

@implementation CHBubbleMsgCellConfiguration

- (instancetype)initWithMID:(NSString *)mid bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid]) {
        _bubbleRect = bubbleRect;
    }
    return self;
}

- (void)setNeedRecalcLayout {
    _bubbleRect = CGRectZero;
    [self setNeedRecalcContentLayout];
}

- (void)setNeedRecalcContentLayout {
}

- (CGSize)calcSize:(CGSize)size {
    if (CGRectIsEmpty(self.bubbleRect)) {
        _bubbleRect.size = [super calcSize:size];
        CGSize sz = [self calcContentSize:self.bubbleRect.size];
        _bubbleRect.size.width = MIN(sz.width, _bubbleRect.size.width);
        _bubbleRect.size.height = MAX(sz.height, _bubbleRect.size.height);
    }
    return self.bubbleRect.size;
}

- (CGSize)calcContentSize:(CGSize)size {
    return size;
}

@end

@implementation CHBubbleMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHView *bubbleView = [CHView new];
    [self addSubview:(_bubbleView = bubbleView)];
    bubbleView.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
    bubbleView.cornerRadius = 8; // Fix: for macOS
}

- (CHView *)contentView {
    return self.bubbleView;
}

- (void)applyConfiguration:(CHBubbleMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    self.bubbleView.frame = configuration.bubbleRect;
}


@end
