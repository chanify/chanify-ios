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

#define kCHImageMessageWidth    150
#define kCHImageMessageHeight   300

@interface CHImageMsgCellContentView : CHMsgCellContentView<CHImageMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHWebImageView *imageView;

@end

@interface CHImageMsgCellConfiguration ()

@property (nonatomic, readonly, nullable, strong) NSString *imageURL;
@property (nonatomic, readonly, assign) CGRect imageRect;
@property (nonatomic, readonly, weak) CHMessagesDataSource *source;

@end

@implementation CHImageMsgCellConfiguration

static UIEdgeInsets imageInsets = { 0, 20, 0, 30 };

+ (instancetype)cellConfiguration:(CHMessageModel *)model source:(CHMessagesDataSource *)source {
    return [[self.class alloc] initWithMID:model.mid imageURL:model.fileURL imageRect:CGRectZero source:source];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid imageURL:self.imageURL imageRect:self.imageRect source:self.source];
}

- (instancetype)initWithMID:(NSString *)mid imageURL:(NSString * _Nullable)imageURL imageRect:(CGRect)imageRect source:(CHMessagesDataSource *)source {
    if (self = [super initWithMID:mid]) {
        _source = source;
        _imageURL = (imageURL ?: @"");
        _imageRect = imageRect;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHImageMsgCellContentView alloc] initWithConfiguration:self];
}

- (void)setNeedRecalcLayout {
    _imageRect = CGRectZero;
}

- (CGFloat)calcHeight:(CGSize)size {
    if (CGRectIsEmpty(self.imageRect)) {
        size.width -= imageInsets.left + imageInsets.right;
        size.height = kCHImageMessageHeight;
        CGSize imageSize = [[CHLogic.shared.imageFileManager loadLocalFile:self.imageURL] size];
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
    return targetSize;
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


@end
