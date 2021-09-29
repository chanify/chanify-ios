//
//  CHLinkMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/4/3.
//

#import "CHLinkMsgCellConfiguration.h"
#import "CHWebLinkManager.h"
#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHLinkMsgCellConfiguration ()

@property (nonatomic, nullable, readonly, strong) NSString *text;
@property (nonatomic, nullable, readonly, strong) NSString *title;
@property (nonatomic, readonly, strong) NSURL *link;

@end

@interface CHLinkMsgCellContentView : CHBubbleMsgCellContentView<CHLinkMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHLabel *detailLabel;
@property (nonatomic, readonly, strong) CHLabel *linkLabel;
@property (nonatomic, readonly, strong) CHImageView *iconView;

@end

@interface CHLinkMsgCellContentView () <CHWebLinkItem>
@end

@implementation CHLinkMsgCellContentView

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
    
    CHImageView *iconView = [CHImageView new];
    [self.bubbleView addSubview:(_iconView = iconView)];
    iconView.contentMode = UIViewContentModeScaleAspectFill;
    iconView.backgroundColor = theme.lightLabelColor;
    iconView.tintColor = theme.labelColor;
    iconView.layer.cornerRadius = 8;
    iconView.clipsToBounds = YES;
    
    CHLabel *detailLabel = [CHLabel new];
    [self.bubbleView addSubview:(_detailLabel = detailLabel)];
    detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    detailLabel.backgroundColor = CHColor.clearColor;
    detailLabel.textColor = theme.minorLabelColor;
    detailLabel.numberOfLines = 2;
    detailLabel.font = theme.messageMediumFont;
    
    CHLabel *linkLabel = [CHLabel new];
    [self.bubbleView addSubview:(_linkLabel = linkLabel)];
    linkLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    linkLabel.backgroundColor = CHColor.clearColor;
    linkLabel.textColor = theme.tintColor;
    linkLabel.numberOfLines = 1;
    linkLabel.font = theme.messageTextFont;
}

- (void)applyConfiguration:(CHLinkMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    
    self.titleLabel.text = configuration.title ?: configuration.link.host;
    self.detailLabel.text = configuration.text ?: @"";
    self.linkLabel.text = configuration.link.absoluteString;

    CGSize size = configuration.bubbleRect.size;
    self.iconView.frame = CGRectMake(size.width - 60, 12, 50, 50);
    self.titleLabel.frame = CGRectMake(12, 8, size.width - 80, 26);
    self.detailLabel.frame = CGRectMake(12, 36, size.width - 80, 48);
    self.linkLabel.frame = CGRectMake(12, size.height - 32, size.width - 24, 24);
    
    [CHLogic.shared.webLinkManager loadLinkFromURL:configuration.link toItem:self];
}

- (NSArray<CHMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [[CHMenuItem alloc]initWithTitle:@"Copy".localized action:@selector(actionCopy:)],
        [[CHMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)],
        [[CHMenuItem alloc]initWithTitle:@"Safari".localized action:@selector(actionOpen:)],
    ]];
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - CHWebLinkItem
- (void)webLinkUpdated:(nullable NSDictionary *)item {
    if (item.count > 0) {
        NSString *hostDesc = [item objectForKey:@"host-desc"];
        if (hostDesc.length > 0) {
            self.titleLabel.text = hostDesc;
        }
        self.iconView.image = [item objectForKey:@"icon"];
        self.detailLabel.text = [item objectForKey:@"title"] ?: @"";
        [self setNeedsDisplay];
    }
}

#pragma mark - Action Methods
- (void)actionCopy:(id)sender {
    [CHPasteboard.shared copyWithName:@"Message".localized value:self.linkURL.absoluteString];
}

- (void)actionOpen:(id)sender {
    [CHRouter.shared routeTo:@"/action/openurl" withParams:@{ @"url": self.linkURL }];
}

- (void)actionShare:(id)sender {
    [CHRouter.shared showShareItem:@[self.linkURL] sender:self.contentView handler:nil];
}

- (void)actionClicked:(CHTapGestureRecognizer *)sender {
    [CHRouter.shared handleURL:self.linkURL];
}

- (NSURL *)linkURL {
    return [(CHLinkMsgCellConfiguration *)self.configuration link];
}


@end

@implementation CHLinkMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title link:model.link bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title link:self.link bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title link:(NSURL * _Nullable)link bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _title = title;
        _text = text;
        _link = link ?: [NSURL new];
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHLinkMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    return CGSizeMake(MIN(size.width, 300), 120);
}


@end
