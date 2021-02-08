//
//  CHTextMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTextMsgCellConfiguration.h"
#import "CHTheme.h"

static UIFont *textFont;
static UIEdgeInsets textInsets = { 8, 12, 8, 12 };

@interface CHTextMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *text;
@property (nonatomic, readonly, assign) CGRect textRect;

@end

@interface CHTextMsgCellContentView : CHMsgCellContentView<CHTextMsgCellConfiguration *>

@property (nonatomic, readonly, strong) UILabel *textLabel;

@end

@implementation CHTextMsgCellContentView

- (void)setupViews {
    UILabel *textLabel = [UILabel new];
    [self.bubbleView addSubview:(_textLabel = textLabel)];
    textLabel.textColor = CHTheme.shared.labelColor;
    textLabel.numberOfLines = 0;
    textLabel.font = textFont;
}

- (void)applyConfiguration:(CHTextMsgCellConfiguration *)configuration {
    self.textLabel.text = configuration.text;
    self.textLabel.frame = configuration.textRect;
}

@end

@implementation CHTextMsgCellConfiguration

+ (void)initialize {
    textFont = [UIFont systemFontOfSize:16];
}

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text textRC:CGRectZero bubbleRC:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text textRC:self.textRect bubbleRC:self.bubbleRect];
}

- (instancetype)initWithMID:(uint64_t)mid text:(NSString * _Nullable)text textRC:(CGRect)textRect bubbleRC:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _text = (text == nil ? @"" : text);
        _textRect = textRect;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHTextMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    if (CGRectIsEmpty(self.textRect)) {
        _textRect.origin.x = textInsets.left;
        _textRect.origin.y = textInsets.top;
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.text attributes:@{
            NSFontAttributeName: textFont,
        }];
        CGRect rc = [text boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        _textRect.size.width = ceil(rc.size.width);
        _textRect.size.height = ceil(rc.size.height);
    }
    return CGSizeMake(self.textRect.size.width + textInsets.left + textInsets.right, self.textRect.size.height + textInsets.top + textInsets.bottom);
}


@end
