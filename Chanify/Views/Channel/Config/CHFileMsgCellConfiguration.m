//
//  CHFileMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/4/7.
//

#import "CHFileMsgCellConfiguration.h"
#import "CHPreviewController.h"
#import "CHWebFileManager.h"
#import "CHPasteboard.h"
#import "CHLogic+iOS.h"
#import "CHRouter+iOS.h"
#import "CHTheme.h"

#define kCHFileMsgCellIconWidth     40

@interface CHFileMsgCellConfiguration ()

@property (nonatomic, nullable, readonly, strong) NSString *text;
@property (nonatomic, nullable, readonly, strong) NSString *title;
@property (nonatomic, nullable, readonly, strong) NSString *filename;
@property (nonatomic, readonly, assign) uint64_t fileSize;
@property (nonatomic, readonly, strong) NSString *fileURL;

@end

@interface CHFileMsgCellContentView : CHBubbleMsgCellContentView<CHFileMsgCellConfiguration *>

@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UILabel *statusLabel;
@property (nonatomic, readonly, strong) UIImageView *iconView;
@property (nonatomic, nullable, readonly, strong) NSURL *localFileURL;

@end

@interface CHFileMsgCellContentView () <CHWebFileItem>
@end

@implementation CHFileMsgCellContentView

- (void)setupViews {
    [super setupViews];
    
    CHTheme *theme = CHTheme.shared;

    UILabel *titleLabel = [UILabel new];
    [self.bubbleView addSubview:(_titleLabel = titleLabel)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textColor = theme.labelColor;
    titleLabel.numberOfLines = 1;
    titleLabel.font = CHTheme.shared.messageTitleFont;

    UILabel *detailLabel = [UILabel new];
    [self.bubbleView addSubview:(_detailLabel = detailLabel)];
    detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    detailLabel.backgroundColor = UIColor.clearColor;
    detailLabel.textColor = theme.minorLabelColor;
    detailLabel.numberOfLines = 2;
    detailLabel.font = [UIFont systemFontOfSize:12];
    
    UILabel *statusLabel = [UILabel new];
    [self.bubbleView addSubview:(_statusLabel = statusLabel)];
    statusLabel.textAlignment = NSTextAlignmentRight;
    statusLabel.backgroundColor = UIColor.clearColor;
    statusLabel.textColor = theme.minorLabelColor;
    statusLabel.numberOfLines = 1;
    statusLabel.font = [UIFont monospacedSystemFontOfSize:8 weight:UIFontWeightRegular];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.fill"]];
    [self.bubbleView addSubview:(_iconView = iconView)];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = theme.lightLabelColor;
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
    [CHLogic.shared.webFileManager loadFileURL:configuration.fileURL filename:configuration.filename toItem:self expectedSize:configuration.fileSize];
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.localFileURL != nil) {
        [items addObject:[[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)]];
    }
    [items addObjectsFromArray:super.menuActions];
    return items;
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

#pragma mark - Action Methods
- (void)actionShare:(id)sender {
    if (self.localFileURL != nil) {
        [CHRouter.shared showShareItem:@[self.localFileURL] sender:self.contentView handler:nil];
    }
}

- (void)actionClicked:(UITapGestureRecognizer *)sender {
    if (self.localFileURL != nil) {
        CHPreviewController *vc = [CHPreviewController previewFile:self.localFileURL];
        [CHRouter.shared presentSystemViewController:vc animated:YES];
    } else {
        CHWebFileManager *webFileManager = CHLogic.shared.webFileManager;
        self.statusLabel.text = @"";
        CHFileMsgCellConfiguration *configuration = (CHFileMsgCellConfiguration *)self.configuration;
        [webFileManager resetFileURLFailed:configuration.fileURL];
        [webFileManager loadFileURL:configuration.fileURL filename:configuration.filename toItem:self expectedSize:configuration.fileSize];
    }
}

@end

@implementation CHFileMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title filename:model.filename fileURL:model.fileURL fileSize:model.fileSize bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title filename:self.filename fileURL:self.fileURL fileSize:self.fileSize bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title filename:(NSString * _Nullable)filename fileURL:(NSString * _Nullable)fileURL fileSize:(uint64_t)fileSize bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _title = title;
        _text = text;
        _filename = filename;
        _fileURL = fileURL;
        _fileSize = fileSize;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHFileMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    return CGSizeMake(MIN(size.width, 300), 80);
}


@end
