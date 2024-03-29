//
//  CHImageMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHImageMsgCellConfiguration.h"
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
@property (nonatomic, readonly, assign) uint64_t fileSize;
@property (nonatomic, readonly, assign) CGRect imageRect;

@end

@implementation CHImageMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid imageURL:model.fileURL fileSize:model.fileSize imageRect:CGRectZero thumbnail:model.thumbnail];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid imageURL:self.imageURL fileSize:self.fileSize imageRect:self.imageRect thumbnail:self.thumbnail];
}

- (instancetype)initWithMID:(NSString *)mid imageURL:(NSString * _Nullable)imageURL fileSize:(uint64_t)fileSize imageRect:(CGRect)imageRect thumbnail:(CHThumbnailModel *)thumbnail {
    if (self = [super initWithMID:mid]) {
        _fileSize = fileSize;
        _imageURL = (imageURL ?: @"");
        _imageRect = imageRect;
        _thumbnail = thumbnail;
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHImageMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcLayout {
    _imageRect = CGRectZero;
}

- (nullable NSString *)mediaThumbnailURL {
    return self.imageURL;
}

- (CGSize)calcSize:(CGSize)size {
    if (CGRectIsEmpty(self.imageRect)) {
        size = [super calcSize:size];
        size.height = kCHImageMessageHeight;
        CGSize imageSize = CGSizeZero;
        if (self.thumbnail != nil) {
            imageSize = CGSizeMake(self.thumbnail.width, self.thumbnail.height);
        }
        if (imageSize.width <= 0 || imageSize.height <= 0) {
            imageSize = [[CHLogic.shared.webImageManager loadLocalFile:self.imageURL] size];
        }
        size = [self calcImageSize:imageSize targetSize:size];
        _imageRect = CGRectMake(0, 0, size.width, size.height);
    }
    return self.imageRect.size;
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
@end

@implementation CHImageMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHWebImageView *imageView = [CHWebImageView new];
    [self addSubview:(_imageView = imageView)];
    imageView.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
    imageView.layer.cornerRadius = 8;
    imageView.delegate = self;
}

- (CHView *)contentView {
    return self.imageView;
}

- (void)applyConfiguration:(CHImageMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    self.imageView.frame = configuration.imageRect;
    [self.imageView loadFileURL:configuration.imageURL expectedSize:configuration.fileSize];
}

- (NSArray<CHMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.imageView.image != nil) {
        [items addObject:[[CHMenuItem alloc] initWithTitle:@"Share".localized action:@selector(actionShare:)]];
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
            [self.source setNeedRecalcLayoutItem:configuration];
        }
    }
}

#pragma mark - Action Methods
- (void)actionShare:(id)sender {
    NSURL *url = self.imageView.localFileSharedURL;
    if (url != nil) {
        [CHRouter.shared showShareItem:@[url] sender:self.contentView handler:nil];
    }
}

- (void)actionClicked:(CHTapGestureRecognizer *)sender {
    NSURL *localFileURL = self.imageView.localFileURL;
    if (localFileURL != nil) {
        CHImageMsgCellConfiguration *configuration = (CHImageMsgCellConfiguration *)self.configuration;
        [self.source previewImageWithMID:configuration.mid];
    }
}


@end
