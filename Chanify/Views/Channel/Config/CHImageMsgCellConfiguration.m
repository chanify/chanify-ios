//
//  CHImageMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHImageMsgCellConfiguration.h"

@interface CHImageMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *image;
@property (nonatomic, readonly, assign) CGRect imageRect;

@end

@implementation CHImageMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid image:model.image imageRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid image:self.image imageRect:self.imageRect];
}

- (instancetype)initWithMID:(NSString *)mid image:(NSString * _Nullable)image imageRect:(CGRect)imageRect {
    if (self = [super initWithMID:mid]) {
        _image = (image ?: @"");
        _imageRect = imageRect;
    }
    return self;
}


@end
