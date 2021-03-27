//
//  CHImageMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHImageMsgCellConfiguration.h"
#import "CHWebImageView.h"
#import "CHTheme.h"

#define kCHImageMessageHeight   200

@interface CHImageMsgCellContentView : CHMsgCellContentView<CHImageMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHWebImageView *imageView;

@end

@interface CHImageMsgCellConfiguration ()

@property (nonatomic, readonly, nullable, strong) NSString *imageURL;
@property (nonatomic, readonly, assign) CGRect imageRect;

@end

@implementation CHImageMsgCellConfiguration

static UIEdgeInsets imageInsets = { 0, 20, 0, 30 };

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid imageURL:model.fileURL imageRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid imageURL:self.imageURL imageRect:self.imageRect];
}

- (instancetype)initWithMID:(NSString *)mid imageURL:(NSString * _Nullable)imageURL imageRect:(CGRect)imageRect {
    if (self = [super initWithMID:mid]) {
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
        size.height -= imageInsets.top + imageInsets.bottom;
        _imageRect = CGRectMake(imageInsets.left, imageInsets.top, 100, kCHImageMessageHeight);
    }
    return self.imageRect.size.height + imageInsets.top + imageInsets.bottom;
}


@end

@implementation CHImageMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHWebImageView *imageView = [CHWebImageView new];
    [self addSubview:(_imageView = imageView)];
    imageView.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
    imageView.layer.cornerRadius = 8;
}

- (UIView *)contentView {
    return self.imageView;
}

- (void)applyConfiguration:(CHImageMsgCellConfiguration *)configuration {
    self.imageView.frame = configuration.imageRect;
    self.imageView.fileURL = configuration.imageURL;
}


@end
