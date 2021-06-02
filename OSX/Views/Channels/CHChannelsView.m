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
#import "CHMessageModel.h"
#import "CHLogic+OSX.h"
#import "CHRouter+OSX.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"CHChannelCellView";

typedef NSCollectionViewDiffableDataSource<NSString *, CHChannelModel *> CHChannelDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHChannelModel *> CHChannelDiffableSnapshot;

@interface CHChannelsView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHLogicDelegate>

@property (nonatomic, readonly, strong) NSCollectionView *listView;
@property (nonatomic, readonly, strong) CHChannelDataSource *dataSource;

@end

@implementation CHChannelsView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        self.hasVerticalScroller = YES;

        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 1;
        NSCollectionView *listView = [NSCollectionView new];
        _listView = listView;
        [listView registerClass:CHChannelCellView.class forItemWithIdentifier:cellIdentifier];
        listView.backgroundColors = @[self.backgroundColor];
        listView.collectionViewLayout = layout;
        listView.allowsMultipleSelection = NO;
        listView.allowsEmptySelection = NO;
        listView.selectable = YES;
        listView.delegate = self;
        self.documentView = listView;

        _dataSource = [[CHChannelDataSource alloc] initWithCollectionView:listView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView * collectionView, NSIndexPath * indexPath, CHChannelModel * model) {
            CHChannelCellView *item = [collectionView makeItemWithIdentifier:cellIdentifier forIndexPath:indexPath];
            if (item != nil) {
                item.model = model;
            }
            return item;
        }];
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
    NSArray<CHChannelModel *> *items = [CHLogic.shared.userDataSource loadChannels];
    CHChannelDiffableSnapshot *snapshot = [CHChannelDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(messageCompare:)]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
    if (self.listView.selectionIndexes.count <= 0 && items.count > 0) {
        NSSet<NSIndexPath *> *indexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]];
        [self.listView selectItemsAtIndexPaths:indexPaths scrollPosition:NSCollectionViewScrollPositionNone];
        [self collectionView:self.listView didSelectItemsAtIndexPaths:indexPaths];
    }
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    CHChannelModel *item = [self.dataSource itemIdentifierForIndexPath:indexPaths.anyObject];
    if (item != nil) {
        [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid, @"show": @"detail" }];
    }
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
    CHUserDataSource *usrDS = CHLogic.shared.userDataSource;
    CHChannelDiffableSnapshot *snapshot = self.dataSource.snapshot;
    NSArray<CHChannelModel *> *items = [snapshot itemIdentifiersInSectionWithIdentifier:@"main"];
    NSHashTable *reloadItems = [NSHashTable weakObjectsHashTable];
    for (NSString *mid in mids) {
        CHMessageModel *model = [usrDS messageWithMID:mid];
        NSString *cid = model.channel.base64;
        for (CHChannelModel *c in items) {
            if ([c.cid isEqualToString:cid]) {
                c.mid = mid;
                [reloadItems addObject:c];
                break;
            }
        }
    }
    if (reloadItems.count != 1 || reloadItems.anyObject != items.firstObject) {
        // TODO: sort items
        [snapshot deleteSectionsWithIdentifiers:@[@"main"]];
        [snapshot appendSectionsWithIdentifiers:@[@"main"]];
        [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(messageCompare:)]];
    }
    [snapshot reloadItemsWithIdentifiers:reloadItems.allObjects];
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
}

- (void)logicMessagesUnreadChanged:(NSNumber *)unread {
}


@end
