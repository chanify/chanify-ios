//
//  CHTextMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTextMsgCellConfiguration.h"
#import "CHPasteboard.h"
#import "CHLinkLabel.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

static CHEdgeInsets textInsets = { 8, 12, 8, 12 };
static CGFloat titleSpace = 4;

@interface CHTextMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *text;
@property (nonatomic, readonly, assign) CGRect textRect;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, assign) CGRect titleRect;

@end

@interface CHTextMsgCellContentView : CHBubbleMsgCellContentView<CHTextMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHLinkLabel *textLabel;
@property (nonatomic, readonly, strong) CHLabel *titleLabel;

@end

@implementation CHTextMsgCellContentView

- (void)setupViews {
    [super setupViews];
    
    CHTheme *theme = CHTheme.shared;

    CHLabel *titleLabel = [CHLabel new];
    [self.bubbleView addSubview:(_titleLabel = titleLabel)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.backgroundColor = CHColor.clearColor;
    titleLabel.textColor = theme.labelColor;
    titleLabel.numberOfLines = 1;
    titleLabel.font = theme.messageTitleFont;

    CHLinkLabel *textLabel = [CHLinkLabel new];
    [self.bubbleView addSubview:(_textLabel = textLabel)];
    textLabel.textColor = theme.labelColor;
    textLabel.linkColor = theme.tintColor;
    textLabel.font = theme.messageTextFont;
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

- (NSArray<CHMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [[CHMenuItem alloc]initWithTitle:@"Copy".localized action:@selector(actionCopy:)],
        [[CHMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)],
    ]];
    [items addObjectsFromArray:super.menuActions];
    return items;
}

- (void)msgCellItemWillUnactive:(id<CHMsgCellItem>)item {
    [self.textLabel clearSelectedText];
}

#pragma mark - Action Methods
- (void)actionClicked:(CHTapGestureRecognizer *)sender {
    [self.textLabel clearSelectedText];
    CGPoint pt = [sender locationInView:self.textLabel];
    [self clickedOnLink:[self.textLabel linkForPoint:pt]];
}

- (nullable CHView *)actionLongClicked:(CHLongPressGestureRecognizer *)recognizer {
    [self.textLabel resetSelectText];
#if !TARGET_OS_OSX
    if (CGRectContainsPoint(self.textLabel.frame, [recognizer locationInView:self.contentView])) {
        return self.textLabel;
    }
#endif
    return [super actionLongClicked:recognizer];
}

- (void)actionCopy:(id)sender {
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    NSString *selectedText = self.textLabel.selectedText;
    if (selectedText.length > 0) {
        [items addObject:selectedText];
    } else {
        if (self.titleLabel.text.length > 0) {
            [items addObject:self.titleLabel.text];
        }
        [items addObject:self.textLabel.text];
    }
    [CHPasteboard.shared copyWithName:@"Message".localized value:[items componentsJoinedByString:@"\n"]];
}

- (void)actionShare:(id)sender {
    [CHRouter.shared showShareItem:@[[(CHTextMsgCellConfiguration *)self.configuration text]] sender:self.contentView handler:nil];
}

#pragma mark - Private Methods
- (void)clickedOnLink:(NSString *)link {
    if (link.length > 0) {
        NSURL *url = [NSURL URLWithString:link];
        if (url.scheme.length <= 0) {
            url = [NSURL URLWithString:[@"http://" stringByAppendingString:link]];
        }
        if (url.scheme.length > 0) {
            [CHRouter.shared handleURL:url];
        }
    }
}

@end

@implementation CHTextMsgCellConfiguration

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

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHTextMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcContentLayout {
    _textRect = CGRectZero;
    _titleRect = CGRectZero;
}

- (CGSize)calcContentSize:(CGSize)size {
    if (CGRectIsEmpty(self.textRect)) {
        CHTheme *theme = CHTheme.shared;
        if (self.title.length <= 0) {
            _titleRect = CGRectZero;
        } else {
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:self.title attributes:@{
                NSFontAttributeName: theme.messageTitleFont,
                NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            }];
            CGRect rc = [title boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, 1) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:nil];
            _titleRect = CGRectMake(textInsets.left, textInsets.top, ceil(rc.size.width), ceil(rc.size.height));
        }
        CGFloat titleOffset = CGRectGetHeight(self.titleRect);
        if (titleOffset > 0) titleOffset += titleSpace;
        _textRect.origin.x = textInsets.left;
        _textRect.origin.y = textInsets.top + titleOffset;
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.text attributes:@{ NSFontAttributeName: theme.messageTextFont }];
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
