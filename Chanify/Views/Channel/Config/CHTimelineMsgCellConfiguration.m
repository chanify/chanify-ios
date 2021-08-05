//
//  CHTimelineMsgCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/8/5.
//

#import "CHTimelineMsgCellConfiguration.h"
#import "CHRouter.h"
#import "CHTheme.h"

#define kCHTimelineTitleHeight      24.0
#define kCHTimelineTitleLabelHeight 20.0

static CHEdgeInsets textInsets = { 8, 12, 8, 12 };

@interface CHTimelineMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, strong) NSString *body;
@property (nonatomic, readonly, assign) CGRect bodyRect;

@end

@interface CHTimelineMsgCellContentView : CHBubbleMsgCellContentView<CHTimelineMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHLabel *bodyLabel;

@end

@implementation CHTimelineMsgCellContentView

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

    CHLabel *bodyLabel = [CHLabel new];
    [self.bubbleView addSubview:(_bodyLabel = bodyLabel)];
    bodyLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    bodyLabel.backgroundColor = CHColor.clearColor;
    bodyLabel.textColor = theme.labelColor;
    bodyLabel.numberOfLines = 3;
    bodyLabel.font = theme.messageSmallFont;
}

- (void)applyConfiguration:(CHTimelineMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];

    CGSize size = self.frame.size;
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:configuration.title];
    [title addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, title.length)];
    self.titleLabel.attributedText = title;
    self.titleLabel.frame = CGRectMake(textInsets.left, textInsets.top, size.width - textInsets.left - textInsets.right, kCHTimelineTitleLabelHeight);
    self.bodyLabel.text = configuration.body;
    self.bodyLabel.frame = configuration.bodyRect;
}

- (NSArray<CHMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [[CHMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)],
    ]];
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - Action Methods
- (void)actionClicked:(CHTapGestureRecognizer *)sender {
}

- (void)actionShare:(id)sender {
    CHTimelineMsgCellConfiguration *configuration = (CHTimelineMsgCellConfiguration *)self.configuration;
    NSString *text = [NSString stringWithFormat:@"%@\n%@", configuration.title, configuration.body];
    [CHRouter.shared showShareItem:@[text] sender:self.contentView handler:nil];
}


@end

@implementation CHTimelineMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    NSString *title = model.title ?: model.code;
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    for (NSString *key in model.timeItems) {
        [items addObject:[NSString stringWithFormat:@"%@:\t%@", key, [model.timeItems valueForKey:key]]];
    }
    NSString *body = [items componentsJoinedByString:@"\n"];
    return [[self.class alloc] initWithMID:model.mid title:title body:body bodyRect:CGRectZero bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid title:self.title body:self.body bodyRect:self.bodyRect bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid title:(NSString * _Nullable)title body:(NSString * _Nullable)body bodyRect:(CGRect)bodyRect bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _title = title ?: @"";
        _body = body ?: @"";
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHTimelineMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcContentLayout {
    _bodyRect = CGRectZero;
}

- (CGSize)calcContentSize:(CGSize)size {
    if (CGRectIsEmpty(self.bodyRect)) {
        CHTheme *theme = CHTheme.shared;
        NSAttributedString *body = [[NSAttributedString alloc] initWithString:self.body attributes:@{
            NSFontAttributeName: theme.messageTextFont,
        }];
        CGRect rc = [body boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:nil];
        _bodyRect = CGRectMake(textInsets.left, textInsets.top + kCHTimelineTitleHeight, ceil(rc.size.width), ceil(rc.size.height));
    }
    CGSize outSize = self.bodyRect.size;
    outSize.width = MAX(outSize.width + textInsets.left + textInsets.right, 200);
    outSize.height += textInsets.top + textInsets.bottom + kCHTimelineTitleHeight;
    return outSize;
}


@end
