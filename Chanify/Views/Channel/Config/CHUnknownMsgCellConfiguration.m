//
//  CHUnknownMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUnknownMsgCellConfiguration.h"
#import "CHTheme.h"

#define kUnknownMessageText   "Unknown message type".localized

static CHEdgeInsets textInsets = { 8, 12, 8, 12 };

@interface CHUnknownMsgCellConfiguration ()

@property (nonatomic, readonly, assign) CGRect textRect;

@end

@interface CHUnknownMsgCellContentView : CHBubbleMsgCellContentView<CHUnknownMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHLabel *textLabel;

@end

@implementation CHUnknownMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHLabel *textLabel = [CHLabel new];
    [self.bubbleView addSubview:(_textLabel = textLabel)];
    textLabel.textColor = CHTheme.shared.tintColor;
    textLabel.numberOfLines = 0;
    textLabel.font = CHTheme.shared.messageTextFont;
}

- (void)applyConfiguration:(CHUnknownMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    self.textLabel.text = @kUnknownMessageText;
    self.textLabel.frame = configuration.textRect;
}

@end

@implementation CHUnknownMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid textRC:CGRectZero bubbleRC:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid textRC:self.textRect bubbleRC:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid textRC:(CGRect)textRect bubbleRC:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _textRect = textRect;
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHUnknownMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcContentLayout {
    _textRect = CGRectZero;
}

- (CGSize)calcContentSize:(CGSize)size {
    if (CGRectIsEmpty(self.textRect)) {
        _textRect.origin.x = textInsets.left;
        _textRect.origin.y = textInsets.top;
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:@kUnknownMessageText attributes:@{
            NSFontAttributeName: CHTheme.shared.messageTextFont,
        }];
        CGRect rc = [text boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        _textRect.size.width = ceil(rc.size.width);
        _textRect.size.height = ceil(rc.size.height);
    }
    return CGSizeMake(self.textRect.size.width + textInsets.left + textInsets.right, self.textRect.size.height + textInsets.top + textInsets.bottom);
}


@end
