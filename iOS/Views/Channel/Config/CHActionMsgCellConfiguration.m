//
//  CHActionMsgCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/5/13.
//

#import "CHActionMsgCellConfiguration.h"
#import "CHActionGroup.h"
#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHTheme.h"

#define kCHActionTitleHeight    26

static UIEdgeInsets textInsets = { 8, 12, 8, 12 };

@interface CHActionMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *text;
@property (nonatomic, readonly, assign) CGFloat textHeight;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, nullable, strong) NSArray<CHActionItemModel *> *actions;

@end

@interface CHActionMsgCellContentView : CHBubbleMsgCellContentView<CHActionMsgCellConfiguration *>

@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *textLabel;
@property (nonatomic, readonly, strong) CHActionGroup *actionGroup;

@end

@interface CHActionMsgCellContentView () <CHActionGroupDelegate>

@end

@implementation CHActionMsgCellContentView

- (void)setupViews {
    [super setupViews];
    
    CHTheme *theme = CHTheme.shared;

    UILabel *titleLabel = [UILabel new];
    [self.bubbleView addSubview:(_titleLabel = titleLabel)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textColor = theme.labelColor;
    titleLabel.numberOfLines = 1;
    titleLabel.font = CHBubbleMsgCellContentView.titleFont;

    UILabel *textLabel = [UILabel new];
    [self.bubbleView addSubview:(_textLabel = textLabel)];
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    textLabel.backgroundColor = UIColor.clearColor;
    textLabel.textColor = theme.labelColor;
    textLabel.numberOfLines = 0;
    textLabel.font = CHBubbleMsgCellContentView.textFont;
    
    CHActionGroup *actionGroup = [CHActionGroup new];
    [self.bubbleView addSubview:(_actionGroup = actionGroup)];
    actionGroup.delegate = self;
}

- (void)applyConfiguration:(CHActionMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    if (configuration.title.length <= 0) {
        self.titleLabel.attributedText = [NSAttributedString new];
    } else {
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:configuration.title];
        [title addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, title.length)];
        self.titleLabel.attributedText = title;
    }
    self.textLabel.text = configuration.text;
    self.actionGroup.actions = configuration.actions;

    CGSize size = configuration.bubbleRect.size;
    CGRect frame = CGRectMake(textInsets.left, textInsets.top, size.width - textInsets.left - textInsets.right, kCHActionTitleHeight);
    if (configuration.title.length <= 0) {
        frame.size.height = 0;
        self.titleLabel.frame = frame;
    } else {
        frame.size.height = ceil([self.titleLabel sizeThatFits:frame.size].height);
        self.titleLabel.frame = frame;
        frame.origin.y += kCHActionTitleHeight;
    }
    frame.size.height = configuration.textHeight;
    self.textLabel.frame = frame;
    self.actionGroup.frame = CGRectMake(0, size.height - CHActionGroup.defaultHeight, size.width, CHActionGroup.defaultHeight);
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [[UIMenuItem alloc]initWithTitle:@"Copy".localized action:@selector(actionCopy:)],
        [[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)],
    ]];
    [items addObjectsFromArray:super.menuActions];
    return items;
}

- (BOOL)canGestureRecognizer:(UIGestureRecognizer *)recognizer {
    if (CGRectContainsPoint(self.actionGroup.bounds, [recognizer locationInView:self.actionGroup])) {
        return NO;
    }
    return [super canGestureRecognizer:recognizer];
}

#pragma mark - CHActionGroupDelegate
- (void)actionGroupSelected:(nullable CHActionItemModel *)item {
    NSURL *link = item.link;
    if (link == nil) {
        [CHRouter.shared makeToast:@"Can't open url".localized];
    } else {
        [CHRouter.shared handleURL:link];
    }
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
    [CHRouter.shared showShareItem:@[[(CHActionMsgCellConfiguration *)self.configuration text]] sender:self.contentView handler:nil];
}

@end

@implementation CHActionMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title textHeight:0 actions:model.actions bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title textHeight:self.textHeight actions:self.actions bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title textHeight:(CGFloat)textHeight actions:(NSArray<CHActionItemModel *> *)actions bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _text = (text ?: @"");
        _title = title;
        _textHeight = textHeight;
        _actions = actions;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHActionMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    if (self.textHeight == 0) {
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.text attributes:@{ NSFontAttributeName: CHBubbleMsgCellContentView.textFont }];
        CGRect rc = [text boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        _textHeight = ceil(rc.size.height);
    }
    CGFloat height = self.textHeight + textInsets.top + textInsets.bottom + CHActionGroup.defaultHeight;
    if (self.title.length > 0) {
        height += kCHActionTitleHeight;
    }
    return CGSizeMake(MIN(size.width, 300), height);
}


@end
