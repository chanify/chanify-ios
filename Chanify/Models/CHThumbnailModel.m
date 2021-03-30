//
//  CHThumbnailModel.m
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHThumbnailModel.h"

@implementation CHThumbnailModel

+ (instancetype)thumbnailWithWidth:(NSUInteger)width height:(NSUInteger)height preview:(nullable NSData *)preview {
    return [[self.class alloc] initWithWidth:width height:height preview:preview];
}

- (instancetype)initWithWidth:(NSUInteger)width height:(NSUInteger)height preview:(nullable NSData *)preview {
    if (self = [super init]) {
        _width = width;
        _height = height;
        _preview = preview;
    }
    return self;
}


@end
