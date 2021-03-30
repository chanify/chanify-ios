//
//  CHWebImageView.m
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import "CHWebImageView.h"
#import "CHLogic.h"

@implementation CHWebImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _fileURL = nil;
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setFileURL:(nullable NSString *)fileURL {
    if (self.fileURL != fileURL && ![self.fileURL isEqualToString:fileURL]) {
        _fileURL = fileURL;
        [CHLogic.shared.imageFileManager loadFileURL:fileURL toItem:self];
    }
}

- (nullable NSURL *)localFileURL {
    return [CHLogic.shared.imageFileManager localFileURL:self.fileURL];
}

#pragma mark - CHWebFileItem
- (void)webFileUpdated:(nullable UIImage *)item {
    if (self.image != item) {
        self.image = item;
        if (self.delegate != nil) {
            [self.delegate webImageViewUpdated:self];
        }
    }
    [self setNeedsDisplay];
}


@end
