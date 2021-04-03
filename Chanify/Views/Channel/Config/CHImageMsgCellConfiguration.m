//
//  CHImageMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHImageMsgCellConfiguration.h"
#import "CHMessagesDataSource.h"
#import "CHWebImageView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

#define kCHImageMessageWidth        150
#define kCHImageMessageHeight       300
#define kCHImageMessageMinWidth     80
#define kCHImageMessageMinHeight    80

@interface CHImageMsgCellContentView : CHMsgCellContentView<CHImageMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHWebImageView *imageView;

@end

@interface CHImageMsgCellConfiguration ()

@property (nonatomic, readonly, nullable, strong) NSString *imageURL;
@property (nonatomic, readonly, nullable, strong) CHThumbnailModel *thumbnail;
@property (nonatomic, readonly, assign) CGRect imageRect;
@property (nonatomic, readonly, weak) CHMessagesDataSource *source;

@end

@implementation CHImageMsgCellConfiguration

static UIEdgeInsets imageInsets = { 0, 20, 0, 30 };

+ (instancetype)cellConfiguration:(CHMessageModel *)model source:(CHMessagesDataSource *)source {
    return [[self.class alloc] initWithMID:model.mid imageURL:model.fileURL imageRect:CGRectZero thumbnail:model.thumbnail source:source];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid imageURL:self.imageURL imageRect:self.imageRect thumbnail:self.thumbnail source:self.source];
}

- (instancetype)initWithMID:(NSString *)mid imageURL:(NSString * _Nullable)imageURL imageRect:(CGRect)imageRect thumbnail:(CHThumbnailModel *)thumbnail source:(CHMessagesDataSource *)source {
    if (self = [super initWithMID:mid]) {
        _source = source;
        _imageURL = (imageURL ?: @"");
        _imageRect = imageRect;
        _thumbnail = thumbnail;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHImageMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcLayout {
    _imageRect = CGRectZero;
}

- (nullable NSString *)mediaThumbnailURL {
    return self.imageURL;
}

- (CGFloat)calcHeight:(CGSize)size {
    if (CGRectIsEmpty(self.imageRect)) {
        size.width -= imageInsets.left + imageInsets.right;
        size.height = kCHImageMessageHeight;
        CGSize imageSize = CGSizeZero;
        if (self.thumbnail != nil) {
            imageSize = CGSizeMake(self.thumbnail.width, self.thumbnail.height);
        }
        if (imageSize.width <= 0 || imageSize.height <= 0) {
            imageSize = [[CHLogic.shared.imageFileManager loadLocalFile:self.imageURL] size];
        }
        size = [self calcImageSize:imageSize targetSize:size];
        _imageRect = CGRectMake(imageInsets.left, imageInsets.top, size.width, size.height);
    }
    return self.imageRect.size.height + imageInsets.top + imageInsets.bottom;
}

- (CGSize)calcImageSize:(CGSize)imageSize targetSize:(CGSize)targetSize {
    if (imageSize.height <= 0) {
        targetSize.width = kCHImageMessageWidth;
    } else {
        if (targetSize.width/targetSize.height >= imageSize.width/imageSize.height) {
            targetSize.width = imageSize.width * targetSize.height / imageSize.height;
        } else {
            targetSize.height = imageSize.height * targetSize.width / imageSize.width;
        }
    }
    return CGSizeMake(MAX(targetSize.width, kCHImageMessageMinWidth), MAX(targetSize.height, kCHImageMessageMinHeight));
}


@end

@interface CHImageMsgCellContentView () <CHWebImageViewDelegate>

@property (nonatomic, readonly, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation CHImageMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHWebImageView *imageView = [CHWebImageView new];
    [self addSubview:(_imageView = imageView)];
    imageView.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
    imageView.layer.cornerRadius = 8;
    imageView.delegate = self;
    imageView.userInteractionEnabled = TRUE;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionShowDetail:)];
    [imageView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)dealloc {
    if (self.tapGestureRecognizer != nil) {
        [self.imageView removeGestureRecognizer:self.tapGestureRecognizer];
        _tapGestureRecognizer = nil;
    }
}

- (UIView *)contentView {
    return self.imageView;
}

- (void)applyConfiguration:(CHImageMsgCellConfiguration *)configuration {
    self.imageView.frame = configuration.imageRect;
    self.imageView.fileURL = configuration.imageURL;
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.imageView.image != nil) {
        [items addObject:[[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)]];
    }
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - CHWebImageViewDelegate
- (void)webImageViewUpdated:(CHWebImageView *)imageView {
    if (imageView.image != nil) {
        CHImageMsgCellConfiguration *configuration = (CHImageMsgCellConfiguration *)self.configuration;
        CGSize size = self.imageView.frame.size;
        CGSize imageSize = [configuration calcImageSize:imageView.image.size targetSize:size];
        if (!CGSizeEqualToSize(size, imageSize)) {
            [configuration.source setNeedRecalcLayoutItem:configuration];
        }
    }
}

#pragma mark - Action Methods
- (void)actionShare:(id)sender {
    [CHRouter.shared showShareItem:@[self.imageView.image] sender:sender handler:nil];
}

- (void)actionShowDetail:(id)sender {
    NSURL *localFileURL = self.imageView.localFileURL;
    if (localFileURL != nil) {
        CHImageMsgCellConfiguration *configuration = (CHImageMsgCellConfiguration *)self.configuration;
        [configuration.source previewImageWithMID:configuration.mid];
    }
}


@end