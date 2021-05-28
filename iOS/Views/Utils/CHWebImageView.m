//
//  CHWebImageView.m
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import "CHWebImageView.h"
#import "CHLoadingView.h"
#import "CHLogic+iOS.h"
#import "CHTheme.h"

#define kCHImageLoadingHeight   60

@interface CHWebImageView ()

@property (nonatomic, readonly, strong) UIImageView *imageView;
@property (nonatomic, nullable, strong) CHLoadingView *loadingView;
@property (nonatomic, readonly, assign) uint64_t expectedSize;

@end

@implementation CHWebImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _image = nil;
        _fileURL = nil;
        _loadingView = nil;
        _expectedSize = 0;
        UIImageView *imageView = [UIImageView new];
        [self addSubview:(_imageView = imageView)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    self.imageView.frame = bounds;
    if (_loadingView != nil) {
        _loadingView.frame = CGRectMake((bounds.size.width - kCHImageLoadingHeight) * 0.5, (bounds.size.height - kCHImageLoadingHeight) * 0.5, kCHImageLoadingHeight, kCHImageLoadingHeight);
    }
}

- (void)loadFileURL:(nullable NSString *)fileURL expectedSize:(uint64_t)expectedSize {
    _expectedSize = expectedSize;
    if (self.fileURL != fileURL && ![self.fileURL isEqualToString:fileURL]) {
        _fileURL = fileURL;
        if (_loadingView != nil) {
            [_loadingView stop:NO];
            _loadingView = nil;
        }
        self.image = nil;
        [CHLogic.shared.webImageManager loadImageURL:fileURL toItem:self expectedSize:expectedSize];
    }
}

- (nullable NSURL *)localFileURL {
    return [CHLogic.shared.webImageManager localFileURL:self.fileURL];
}

- (void)setImage:(nullable UIImage *)image {
    if (self.image != image) {
        _image = image;
        self.imageView.image = image ?: CHTheme.shared.clearImage;
        [self setNeedsDisplay];
    }
}

#pragma mark - Actions Methods
- (void)actionReload:(id)sender {
    [self.loadingView reset];
    [CHLogic.shared.webImageManager resetFileURLFailed:self.fileURL];
    [CHLogic.shared.webImageManager loadImageURL:self.fileURL toItem:self expectedSize:self.expectedSize];
}

#pragma mark - CHWebImageItem
- (void)webImageUpdated:(nullable CHImage *)item fileURL:(nullable NSString *)fileURL {
    if ([self.fileURL isEqualToString:fileURL]) {
        if (item == nil) {
            [self.loadingView switchToFailed];
        } else {
            if (_loadingView != nil) {
                [_loadingView stop:YES];
                _loadingView = nil;
            }
        }
        if (self.image != item) {
            self.image = item;
            if (self.delegate != nil) {
                [self.delegate webImageViewUpdated:self];
            }
        }
    }
}

- (void)webImageProgress:(double)progress fileURL:(nullable NSString *)fileURL {
    if ([self.fileURL isEqualToString:fileURL]) {
        if (progress < 1) {
            self.loadingView.progress = progress;
        } else {
            if (_loadingView != nil) {
                [_loadingView stop:YES];
                _loadingView = nil;
            }
        }
    }
}

#pragma mark - Private Methods
- (CHLoadingView *)loadingView {
    if (_loadingView == nil) {
        [self addSubview:(_loadingView = [CHLoadingView loadingViewWithTarget:self action:@selector(actionReload:)])];
    }
    return _loadingView;
}


@end
