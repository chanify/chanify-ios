//
//  CHCollectionView.m
//  OSX
//
//  Created by WizJin on 2021/6/2.
//

#import "CHCollectionView.h"

@implementation CHCollectionView

- (instancetype)initWithLayout:(NSCollectionViewFlowLayout *)layout {
    if (self = [super initWithFrame:NSZeroRect]) {
        layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
        self.collectionViewLayout = layout;
    }
    return self;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeWithOldSuperviewSize:oldSize];
    if (self.bounds.size.width != oldSize.width) {
        [self.collectionViewLayout invalidateLayout];
    }
}

- (void)setBackgroundColor:(NSColor *)color {
    self.backgroundColors = @[color];
}


@end
