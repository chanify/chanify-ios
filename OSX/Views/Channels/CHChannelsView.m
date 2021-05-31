//
//  CHChannelsView.m
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHChannelsView.h"
#import <Masonry/Masonry.h>
#import "CHChannelCellItem.h"

static NSString *const cellIdentifier = @"CHChannelCellItem";

@interface CHChannelsView () <NSCollectionViewDelegateFlowLayout, NSCollectionViewDelegate, NSCollectionViewDataSource>

@property (nonatomic, readonly, strong) NSCollectionView *listView;

@end

@implementation CHChannelsView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
        layout.itemSize = NSMakeSize(600, 100);
        NSCollectionView *listView = [NSCollectionView new];
        [self addSubview:(_listView = listView)];
        [listView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [listView registerClass:CHChannelCellItem.class forItemWithIdentifier:cellIdentifier];
        listView.collectionViewLayout = layout;
        listView.dataSource = self;
        listView.delegate = self;
    }
    return self;
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [collectionView deselectItemsAtIndexPaths:indexPaths];
}

#pragma mark - NSCollectionViewDataSource
- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView makeItemWithIdentifier:cellIdentifier forIndexPath:indexPath];
}


@end
