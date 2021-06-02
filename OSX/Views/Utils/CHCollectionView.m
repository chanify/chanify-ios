//
//  CHCollectionView.m
//  OSX
//
//  Created by WizJin on 2021/6/2.
//

#import "CHCollectionView.h"

@interface CHCollectionView ()

@property (nonatomic, assign) CGFloat lastWidth;

@end

@implementation CHCollectionView

- (instancetype)initWithLayout:(NSCollectionViewFlowLayout *)layout {
    if (self = [super initWithFrame:NSZeroRect]) {
        _lastWidth = 0;
        layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
        self.collectionViewLayout = layout;
    }
    return self;
}

- (void)layout {
    if (self.bounds.size.width != self.lastWidth) {
        self.lastWidth = self.bounds.size.width;
        [self.collectionViewLayout invalidateLayout];
    }
    [super layout];
}

- (void)setBackgroundColor:(NSColor *)color {
    self.backgroundColors = @[color];
}


@end
