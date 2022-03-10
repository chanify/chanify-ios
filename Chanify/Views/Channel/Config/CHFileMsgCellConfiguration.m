//
//  CHFileMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/4/7.
//

#import "CHFileMsgCellConfiguration.h"
#import "CHWebFileManager.h"
#import "CHActionGroup.h"
#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

#define kCHFileMsgCellIconWidth     40

@interface CHFileMsgCellConfiguration ()

@property (nonatomic, nullable, readonly, strong) NSString *text;
@property (nonatomic, nullable, readonly, strong) NSString *title;
@property (nonatomic, nullable, readonly, strong) NSString *filename;
@property (nonatomic, readonly, assign) uint64_t fileSize;
@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, nullable, strong) NSArray<CHActionItemModel *> *actions;

@end

@interface CHFileMsgCellContentView : CHBubbleMsgCellContentView<CHFileMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHLabel *detailLabel;
@property (nonatomic, readonly, strong) CHLabel *statusLabel;
@property (nonatomic, readonly, strong) CHImageView *iconView;
@property (nonatomic, readonly, strong) CHActionGroup *actionGroup;
@property (nonatomic, nullable, readonly, strong) NSURL *localFileURL;

@end

@interface CHFileMsgCellContentView () <CHWebFileItem, CHActionGroupDelegate>
@end

@implementation CHFileMsgCellContentView

- (void)setupViews {
    [super setupViews];
    
    CHTheme *theme = CHTheme.shared;

    CHLabel *titleLabel = [CHLabel new];
    [self.bubbleView addSubview:(_titleLabel = titleLabel)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    titleLabel.backgroundColor = CHColor.clearColor;
    titleLabel.textColor = theme.labelColor;
    titleLabel.numberOfLines = 1;
    titleLabel.font = CHTheme.shared.messageTitleFont;

    CHLabel *detailLabel = [CHLabel new];
    [self.bubbleView addSubview:(_detailLabel = detailLabel)];
    detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    detailLabel.backgroundColor = CHColor.clearColor;
    detailLabel.textColor = theme.minorLabelColor;
    detailLabel.numberOfLines = 2;
    detailLabel.font = theme.messageSmallFont;
    
    CHLabel *statusLabel = [CHLabel new];
    [self.bubbleView addSubview:(_statusLabel = statusLabel)];
    statusLabel.textAlignment = NSTextAlignmentRight;
    statusLabel.backgroundColor = CHColor.clearColor;
    statusLabel.textColor = theme.minorLabelColor;
    statusLabel.numberOfLines = 1;
    statusLabel.font = theme.messageSmallDigitalFont;
    
    CHImageView *iconView = [[CHImageView alloc] initWithImage:[CHImage systemImageNamed:@"doc.fill"]];
    [self.bubbleView addSubview:(_iconView = iconView)];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = theme.lightLabelColor;
    
    CHActionGroup *actionGroup = [CHActionGroup new];
    [self.bubbleView addSubview:(_actionGroup = actionGroup)];
    actionGroup.delegate = self;
}

- (void)applyConfiguration:(CHFileMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];

    self.titleLabel.text = configuration.title ?: configuration.filename;
    if (self.titleLabel.text <= 0) {
        self.titleLabel.text = configuration.text ?: @"FileMsg".localized;
    } else {
        self.detailLabel.text = configuration.text;
    }

    CGSize size = configuration.bubbleRect.size;
    
    if (configuration.actions.count <= 0) {
        self.actionGroup.actions = @[];
        self.actionGroup.hidden = YES;
    } else {
        size.height -= CHActionGroup.defaultHeight;
        self.actionGroup.actions = configuration.actions;
        self.actionGroup.frame = CGRectMake(0, size.height, size.width, CHActionGroup.defaultHeight);
        self.actionGroup.hidden = NO;
    }
    CGFloat offset = kCHFileMsgCellIconWidth + 20;
    CGFloat width = size.width - kCHFileMsgCellIconWidth - 30;
    self.statusLabel.frame = CGRectMake(offset, size.height - 16, width, 10);
    self.iconView.frame = CGRectMake(10, 10, kCHFileMsgCellIconWidth, size.height - 20);
    if (self.detailLabel.text.length <= 0) {
        self.titleLabel.frame = CGRectMake(offset, 10, width, size.height - 25);
        self.detailLabel.frame = CGRectZero;
        self.titleLabel.numberOfLines = 3;
    } else {
        self.titleLabel.frame = CGRectMake(offset, 10, width, 16);
        self.detailLabel.frame = CGRectMake(offset, 27, width, size.height - 44);
        self.titleLabel.numberOfLines = 1;
    }

    _localFileURL = nil;
    self.statusLabel.text = @"";
    [CHLogic.shared.webFileManager loadFileURL:configuration.fileURL filename:configuration.filename toItem:self expectedSize:configuration.fileSize network:NO];
}

- (NSArray<CHMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.localFileURL != nil) {
        [items addObject:[[CHMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)]];
    }
    [items addObjectsFromArray:super.menuActions];
    return items;
}

- (BOOL)canGestureRecognizer:(CHGestureRecognizer *)recognizer {
    if (CGRectContainsPoint(self.actionGroup.bounds, [recognizer locationInView:self.actionGroup])) {
        return NO;
    }
    return [super canGestureRecognizer:recognizer];
}

#pragma mark - CHWebFileItem
- (void)webFileUpdated:(nullable NSURL *)item fileURL:(nullable NSString *)fileURL {
    CHFileMsgCellConfiguration *configuration = (CHFileMsgCellConfiguration *)self.configuration;
    if ([configuration.fileURL isEqualToString:fileURL]) {
        _localFileURL = item;
        if (item == nil) {
            self.statusLabel.text = @"Download failed and click to retry".localized;
        } else {
            self.statusLabel.text = [@(configuration.fileSize ?: self.localFileURL.fileSize) formatFileSize];
        }
    }
}

- (void)webFileProgress:(double)progress fileURL:(nullable NSString *)fileURL {
    CHFileMsgCellConfiguration *configuration = (CHFileMsgCellConfiguration *)self.configuration;
    if ([configuration.fileURL isEqualToString:fileURL]) {
        self.statusLabel.text = [NSString stringWithFormat:@"Downloading %6.02f%%".localized, progress * 100];
    }
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
- (void)actionShare:(id)sender {
    if (self.localFileURL != nil) {
        [CHRouter.shared showShareItem:@[self.localFileURL] sender:self.contentView handler:nil];
    }
}

- (void)actionClicked:(CHTapGestureRecognizer *)sender {
    if (self.localFileURL != nil) {
        [CHRouter.shared routeTo:@"/action/previewfile" withParams:@{ @"url": self.localFileURL }];
    } else {
        CHWebFileManager *webFileManager = CHLogic.shared.webFileManager;
        self.statusLabel.text = @"";
        CHFileMsgCellConfiguration *configuration = (CHFileMsgCellConfiguration *)self.configuration;
        [webFileManager resetFileURLFailed:configuration.fileURL];
        [webFileManager loadFileURL:configuration.fileURL filename:configuration.filename toItem:self expectedSize:configuration.fileSize network:YES];
    }
}

@end

@implementation CHFileMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title filename:model.filename fileURL:model.fileURL fileSize:model.fileSize actions:model.actions bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title filename:self.filename fileURL:self.fileURL fileSize:self.fileSize actions:self.actions bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title filename:(NSString * _Nullable)filename fileURL:(NSString * _Nullable)fileURL fileSize:(uint64_t)fileSize actions:(NSArray<CHActionItemModel *> * _Nullable)actions bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _title = title;
        _text = text;
        _filename = filename;
        _fileURL = fileURL;
        _fileSize = fileSize;
        _actions = actions;
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHFileMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    CGFloat height = 80;
    if (self.actions.count > 0) {
        height += CHActionGroup.defaultHeight;
    }
    return CGSizeMake(MIN(size.width, 300), height);
}


@end
