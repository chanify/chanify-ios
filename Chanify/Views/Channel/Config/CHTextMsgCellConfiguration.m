//
//  CHTextMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTextMsgCellConfiguration.h"
#import <M80AttributedLabel/M80AttributedLabel.h>
#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

static UIFont *textFont;
static UIFont *titleFont;
static UIEdgeInsets textInsets = { 8, 12, 8, 12 };
static CGFloat titleSpace = 4;

@interface CHTextMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *text;
@property (nonatomic, readonly, assign) CGRect textRect;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, assign) CGRect titleRect;

@end

@interface CHTextMsgCellContentView : CHBubbleMsgCellContentView<CHTextMsgCellConfiguration *>

@property (nonatomic, readonly, strong) M80AttributedLabel *textLabel;
@property (nonatomic, readonly, strong) UILabel *titleLabel;

@end

@interface CHTextMsgCellContentView () <M80AttributedLabelDelegate>

@end

@implementation CHTextMsgCellContentView

- (void)setupViews {
    [super setupViews];
    
    CHTheme *theme = CHTheme.shared;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.bubbleView addSubview:(_titleLabel = titleLabel)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textColor = theme.labelColor;
    titleLabel.numberOfLines = 1;
    titleLabel.font = titleFont;

    M80AttributedLabel *textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
    [self.bubbleView addSubview:(_textLabel = textLabel)];
    textLabel.backgroundColor = UIColor.clearColor;
    textLabel.textColor = theme.labelColor;
    textLabel.linkColor = theme.tintColor;
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    textLabel.autoDetectLinks = YES;
    textLabel.numberOfLines = 0;
    textLabel.font = textFont;
    textLabel.delegate = self;
}

- (void)applyConfiguration:(CHTextMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    if (configuration.title.length <= 0) {
        self.titleLabel.attributedText = [NSAttributedString new];
    } else {
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:configuration.title];
        [title addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, title.length)];
        self.titleLabel.attributedText = title;
    }
    self.titleLabel.frame = configuration.titleRect;
    self.titleLabel.hidden = (configuration.title.length <= 0);
    self.textLabel.text = configuration.text;
    self.textLabel.frame = configuration.textRect;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        // Note: Fix dark mode for M80AttributedLabel
        self.textLabel.text = [(CHTextMsgCellConfiguration *)self.configuration text];
        [self setNeedsDisplay];
    }
    [super traitCollectionDidChange:previousTraitCollection];
}

#pragma mark - M80AttributedLabelDelegate
- (void)m80AttributedLabel:(M80AttributedLabel *)label clickedOnLink:(id)linkData {
    UIMenuController *menu = UIMenuController.sharedMenuController;
    if (menu.isMenuVisible) {
        [menu hideMenuFromView:self.bubbleView];
    }
    if ([linkData isKindOfClass:NSString.class]) {
        NSURL *url = [NSURL URLWithString:(NSString *)linkData];
        if (url.scheme.length <= 0) {
            url = [NSURL URLWithString:[@"http://" stringByAppendingString:linkData]];
        }
        if (url.scheme.length > 0) {
            [CHRouter.shared handleURL:url];
        }
    }
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [[UIMenuItem alloc]initWithTitle:@"Copy".localized action:@selector(actionCopy:)],
        [[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)],
    ]];
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - Action Methods
- (void)actionCopy:(id)sender {
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    if (self.titleLabel.text.length > 0) {
        [items addObject:self.titleLabel.text];
    }
    [items addObject:self.textLabel.text];
    [CHPasteboard.shared copyWithName:@"Message".localized value:[items componentsJoinedByString:@"\n"]];
}

- (void)actionShare:(id)sender {
    [CHRouter.shared showShareItem:@[[(CHTextMsgCellConfiguration *)self.configuration text]] sender:sender handler:nil];
}


@end

@implementation CHTextMsgCellConfiguration

+ (void)initialize {
    textFont = [UIFont systemFontOfSize:16];
    titleFont = [UIFont boldSystemFontOfSize:16];
}

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title textRect:CGRectZero titleRect:CGRectZero bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title textRect:self.textRect titleRect:self.titleRect bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title textRect:(CGRect)textRect titleRect:(CGRect)titleRect bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _text = (text ?: @"");
        _title = title;
        _textRect = textRect;
        _titleRect = titleRect;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHTextMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcContentLayout {
    _textRect = CGRectZero;
    _titleRect = CGRectZero;
}

- (CGSize)calcContentSize:(CGSize)size {
    if (CGRectIsEmpty(self.textRect)) {
        if (self.title.length <= 0) {
            _titleRect = CGRectZero;
        } else {
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:self.title attributes:@{
                NSFontAttributeName: titleFont,
                NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            }];
            CGRect rc = [title boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, 1) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:nil];
            _titleRect = CGRectMake(textInsets.left, textInsets.top, ceil(rc.size.width), ceil(rc.size.height));
        }
        CGFloat titleOffset = CGRectGetHeight(self.titleRect);
        if (titleOffset > 0) titleOffset += titleSpace;
        _textRect.origin.x = textInsets.left;
        _textRect.origin.y = textInsets.top + titleOffset;
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.text attributes:@{ NSFontAttributeName: textFont }];
        CGRect rc = [text boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right - titleOffset, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        _textRect.size.width = ceil(rc.size.width);
        _textRect.size.height = ceil(rc.size.height);
    }
    CGSize outSize = self.textRect.size;
    if (!CGRectIsEmpty(self.titleRect)) {
        outSize.width = MAX(outSize.width, self.titleRect.size.width);
        outSize.height += self.titleRect.size.height + titleSpace;
    }
    outSize.width += textInsets.left + textInsets.right;
    outSize.height += textInsets.top + textInsets.bottom;
    return outSize;
}


@end
