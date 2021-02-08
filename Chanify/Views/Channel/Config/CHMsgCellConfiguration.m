//
//  CHMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMsgCellConfiguration.h"
#import "CHTheme.h"

@implementation CHMsgCellConfiguration

static UIEdgeInsets bubbleInsets = { 0, 20, 0, 30 };

- (instancetype)initWithMID:(uint64_t)mid bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid]) {
        _bubbleRect = bubbleRect;
    }
    return self;
}

- (CGFloat)calcHeight:(CGSize)size {
    if (CGRectIsEmpty(self.bubbleRect)) {
        _bubbleRect.origin.x = bubbleInsets.left;
        _bubbleRect.origin.y = bubbleInsets.top;
        _bubbleRect.size.width = size.width - bubbleInsets.left - bubbleInsets.right;
        _bubbleRect.size.height = size.height - bubbleInsets.top - bubbleInsets.bottom;
        CGSize sz = [self calcContentSize:self.bubbleRect.size];
        _bubbleRect.size.width = MIN(sz.width, size.width);
        _bubbleRect.size.height = MAX(sz.height, size.height);
    }
    return self.bubbleRect.size.height + bubbleInsets.top + bubbleInsets.bottom;
}

- (CGSize)calcContentSize:(CGSize)size {
    return size;
}

@end

@implementation CHMsgCellContentView

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _configuration = nil;
        
        UIView *bubbleView = [UIView new];
        [self addSubview:(_bubbleView = bubbleView)];
        bubbleView.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
        bubbleView.layer.cornerRadius = 8;
        
        [self setupViews];
        
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(CHMsgCellConfiguration *)configuration {
    if (![self.configuration isEqual:configuration]) {
        _configuration = configuration;

        self.bubbleView.frame = configuration.bubbleRect;
        
        [self applyConfiguration:configuration];
    }
}

- (void)applyConfiguration:(CHMsgCellConfiguration *)configuration {
    
}

- (void)setupViews {
    
}


@end
