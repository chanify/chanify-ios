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

#pragma mark - CHWebFileItem
- (BOOL)webFileUpdated:(nullable NSData *)data {
    if (data.length <= 0) {
        self.image = nil;
    } else {
        self.image = [UIImage imageWithData:data];
    }
    [self setNeedsDisplay];
    return (self.image != nil);
}


@end
