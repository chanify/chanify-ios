//
//  CHLinkMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/4/3.
//

#import "CHLinkMsgCellConfiguration.h"
#import "CHLinkMetaManager.h"
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

@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UILabel *linkLabel;
@property (nonatomic, readonly, strong) UIImageView *iconView;
@property (nonatomic, readonly, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@interface CHLinkMsgCellContentView () <CHLinkMetaItem>
@end

@implementation CHLinkMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHTheme *theme = CHTheme.shared;

    UILabel *titleLabel = [UILabel new];
    [self.bubbleView addSubview:(_titleLabel = titleLabel)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textColor = theme.labelColor;
    titleLabel.numberOfLines = 1;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    
    UIImageView *iconView = [UIImageView new];
    [self.bubbleView addSubview:(_iconView = iconView)];
    iconView.contentMode = UIViewContentModeScaleAspectFill;
    iconView.backgroundColor = theme.lightLabelColor;
    iconView.layer.cornerRadius = 8;
    iconView.clipsToBounds = YES;
    
    UILabel *detailLabel = [UILabel new];
    [self.bubbleView addSubview:(_detailLabel = detailLabel)];
    detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    detailLabel.backgroundColor = UIColor.clearColor;
    detailLabel.textColor = theme.minorLabelColor;
    detailLabel.numberOfLines = 2;
    detailLabel.font = [UIFont systemFontOfSize:15];
    
    UILabel *linkLabel = [UILabel new];
    [self.bubbleView addSubview:(_linkLabel = linkLabel)];
    linkLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    linkLabel.backgroundColor = UIColor.clearColor;
    linkLabel.textColor = theme.tintColor;
    linkLabel.numberOfLines = 1;
    linkLabel.font = [UIFont systemFontOfSize:16];

    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionShowURL:)];
    [self.contentView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)dealloc {
    if (self.tapGestureRecognizer != nil) {
        [self.contentView removeGestureRecognizer:self.tapGestureRecognizer];
        _tapGestureRecognizer = nil;
    }
}

- (void)applyConfiguration:(CHLinkMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    
    self.titleLabel.text = configuration.title ?: configuration.link.host;
    //self.detailLabel.text = configuration.text ?: configuration.text;
    self.linkLabel.text = configuration.link.absoluteString;

    CGSize size = configuration.bubbleRect.size;
    self.iconView.frame = CGRectMake(size.width - 60, 12, 50, 50);
    self.titleLabel.frame = CGRectMake(12, 8, size.width - 80, 26);
    self.detailLabel.frame = CGRectMake(12, 36, size.width - 80, 48);
    self.linkLabel.frame = CGRectMake(12, size.height - 32, size.width - 24, 24);
    
    [CHLogic.shared.linkMetaManager loadMetaFromURL:configuration.link toItem:self];
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [[UIMenuItem alloc]initWithTitle:@"Copy".localized action:@selector(actionCopy:)],
        [[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)],
    ]];
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - CHLinkMetaItem
- (void)linkMetaUpdated:(nullable NSDictionary *)item {
    if (item.count > 0) {
        self.iconView.image = [item objectForKey:@"icon"];
        self.detailLabel.text = [item objectForKey:@"title"] ?: @"";
        [self setNeedsDisplay];
    }
}

#pragma mark - Action Methods
- (void)actionCopy:(id)sender {
    [CHPasteboard.shared copyWithName:@"Message".localized value:self.linkLabel.text];
}

- (void)actionShare:(id)sender {
    [CHRouter.shared showShareItem:@[[(CHLinkMsgCellConfiguration *)self.configuration link]] sender:sender handler:nil];
}

- (void)actionShowURL:(id)sender {
    [CHRouter.shared handleURL:[(CHLinkMsgCellConfiguration *)self.configuration link]];
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

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHLinkMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    return CGSizeMake(MIN(size.width, 300), 120);
}


@end
