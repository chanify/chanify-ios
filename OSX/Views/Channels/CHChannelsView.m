//
//  CHChannelsView.m
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHChannelsView.h"
#import <Masonry/Masonry.h>
#import "CHChannelCellView.h"
#import "CHUserDataSource.h"
#import "CHLogic+OSX.h"
#import "CHRouter+OSX.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"CHChannelCellView";

@interface CHChannelsView () <NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, CHLogicDelegate>

@property (nonatomic, readonly, strong) NSCollectionView *listView;
@property (nonatomic, readonly, strong) NSArray<CHChannelModel *> *items;

@end

@implementation CHChannelsView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.backgroundColor = CHTheme.shared.groupedBackgroundColor;

        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 1;
        NSCollectionView *listView = [NSCollectionView new];
        [self addSubview:(_listView = listView)];
        [listView registerClass:CHChannelCellView.class forItemWithIdentifier:cellIdentifier];
        listView.backgroundColors = @[self.backgroundColor];
        listView.collectionViewLayout = layout;
        listView.allowsMultipleSelection = NO;
        listView.allowsEmptySelection = NO;
        listView.selectable = YES;
        listView.dataSource = self;
        listView.delegate = self;
        self.documentView = listView;
        self.hasVerticalScroller = YES;
        
        [CHLogic.shared addDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)layout {
    [super layout];
    [self.listView.collectionViewLayout invalidateLayout];
}

- (void)reloadData {
    _items = [CHLogic.shared.userDataSource loadChannels];
    [self.listView reloadData];
    if (self.listView.selectionIndexes.count <= 0 && self.items.count > 0) {
        NSSet<NSIndexPath *> *indexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]];
        [self.listView selectItemsAtIndexPaths:indexPaths scrollPosition:NSCollectionViewScrollPositionNone];
        [self collectionView:self.listView didSelectItemsAtIndexPaths:indexPaths];
    }
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    CHChannelModel *item = [self.items objectAtIndex:indexPaths.anyObject.item];
    if (item != nil) {
        [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid, @"show": @"detail" }];
    }
}

#pragma mark - NSCollectionViewDataSource
- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    CHChannelCellView *item = [collectionView makeItemWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (item != nil) {
        item.model = [self.items objectAtIndex:indexPath.item];
    }
    return item;
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width, 60);
}

#pragma mark - CHLogicDelegate
- (void)logicChannelUpdated:(NSString *)cid {
    [self reloadData];
}

- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids {
    [self reloadData];
}

- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids {
    [self reloadData];
}

- (void)logicMessagesUnreadChanged:(NSNumber *)unread {
}


@end
