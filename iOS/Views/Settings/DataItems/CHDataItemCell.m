//
//  CHDataItemCell.m
//  iOS
//
//  Created by WizJin on 2021/5/26.
//

#import "CHDataItemCell.h"

@implementation CHDataItemCell

+ (CGFloat)cellHeight {
    return 32;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.contentView.frame;
    frame.origin.x = (self.isEditing ? 40 : 0);
    frame.size.width = self.bounds.size.width - frame.origin.x;
    self.contentView.frame = frame;
}

- (void)setURL:(NSURL *)url manager:(CHWebCacheManager *)manager {
}


@end
