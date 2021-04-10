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
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHFileMsgCellConfiguration ()

@property (nonatomic, nullable, readonly, strong) NSString *text;
@property (nonatomic, nullable, readonly, strong) NSString *title;
@property (nonatomic, nullable, readonly, strong) NSString *filename;
@property (nonatomic, readonly, strong) NSString *fileURL;

@end

@interface CHFileMsgCellContentView : CHBubbleMsgCellContentView<CHFileMsgCellConfiguration *>

@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UIImageView *iconView;
@property (nonatomic, readonly, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, nullable, readonly, strong) NSURL *loaclFileURL;

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
    titleLabel.font = [UIFont boldSystemFontOfSize:16];

    UILabel *detailLabel = [UILabel new];
    [self.bubbleView addSubview:(_detailLabel = detailLabel)];
    detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    detailLabel.backgroundColor = UIColor.clearColor;
    detailLabel.textColor = theme.minorLabelColor;
    detailLabel.numberOfLines = 2;
    detailLabel.font = [UIFont systemFontOfSize:15];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.fill"]];
    [self.bubbleView addSubview:(_iconView = iconView)];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = theme.lightLabelColor;

    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionShowFile:)];
    [self.contentView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)dealloc {
    if (self.tapGestureRecognizer != nil) {
        [self.contentView removeGestureRecognizer:self.tapGestureRecognizer];
        _tapGestureRecognizer = nil;
    }
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
    self.iconView.frame = CGRectMake(10, 10, 40, size.height - 20);
    if (self.detailLabel.text.length <= 0) {
        self.titleLabel.frame = CGRectMake(60, 8, size.width - size.height, size.height - 16);
        self.detailLabel.frame = CGRectZero;
        self.titleLabel.numberOfLines = 3;
    } else {
        self.titleLabel.frame = CGRectMake(60, 8, size.width - size.height, 20);
        self.detailLabel.frame = CGRectMake(60, 30, size.width - 80, size.height - 38);
        self.titleLabel.numberOfLines = 1;
    }
    
    _loaclFileURL = nil;
    [CHLogic.shared.webFileManager loadFileURL:configuration.fileURL filename:configuration.filename toItem:self];
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.loaclFileURL != nil) {
        [items addObject:[[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)]];
    }
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - CHWebFileItem
- (void)webFileUpdated:(nullable NSURL *)item {
    _loaclFileURL = item;
}

#pragma mark - Action Methods
- (void)actionShare:(id)sender {
    if (self.loaclFileURL != nil) {
        [CHRouter.shared showShareItem:@[self.loaclFileURL] sender:sender handler:nil];
    }
}

- (void)actionShowFile:(id)sender {
    if (self.loaclFileURL != nil) {
        CHPreviewController *vc = [CHPreviewController previewFile:self.loaclFileURL];
        [CHRouter.shared presentSystemViewController:vc animated:YES];
    }
}

@end

@implementation CHFileMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title filename:model.filename fileURL:model.file bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title filename:self.filename fileURL:self.fileURL bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title filename:(NSString * _Nullable)filename fileURL:(NSString * _Nullable)fileURL bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _title = title;
        _text = text;
        _filename = filename;
        _fileURL = fileURL;
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
