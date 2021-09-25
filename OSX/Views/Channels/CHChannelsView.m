//
//  CHChannelsView.m
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHChannelsView.h"
#import "CHChannelCellView.h"
#import "CHCollectionView.h"
#import "CHScrollView.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"CHChannelCellView";

typedef NSCollectionViewDiffableDataSource<NSString *, CHChannelModel *> CHChannelDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHChannelModel *> CHChannelDiffableSnapshot;

@interface CHChannelsView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHChannelDataSource *dataSource;
@property (nonatomic, nullable, strong) CHChannelModel *selected;

@end

@implementation CHChannelsView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _selected = nil;
        
        CHTheme *theme = CHTheme.shared;
        self.backgroundColor = theme.groupedBackgroundColor;
        self.rightBarButtonItem = [CHBarButtonItem itemWithIcon:@"plus" target:self action:@selector(actionAddChannel:)];

        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 1;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        [listView registerClass:CHChannelCellView.class forItemWithIdentifier:cellIdentifier];
        listView.backgroundColor = theme.groupedBackgroundColor;
        listView.allowsMultipleSelection = NO;
        listView.allowsEmptySelection = NO;
        listView.selectable = YES;
        listView.delegate = self;

        CHScrollView *scrollView = [CHScrollView new];
        [self addSubview:(_scrollView = scrollView)];
        scrollView.documentView = listView;
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = NO;
        
        @weakify(self);
        _dataSource = [[CHChannelDataSource alloc] initWithCollectionView:listView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView * collectionView, NSIndexPath * indexPath, CHChannelModel * model) {
            CHChannelCellView *item = [collectionView makeItemWithIdentifier:cellIdentifier forIndexPath:indexPath];
            if (item != nil) {
                @strongify(self);
                item.model = model;
                item.selected = ([self.selected isEqualTo:model]);
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
    self.scrollView.frame = self.bounds;
}

- (void)reloadData {
    NSArray<CHChannelModel *> *items = [CHLogic.shared.userDataSource loadChannels];
    CHChannelDiffableSnapshot *snapshot = [CHChannelDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(messageCompare:)]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
    [self fixSelectChannel];
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    CHChannelModel *item = [self.dataSource itemIdentifierForIndexPath:indexPaths.anyObject];
    if (item != nil && ![item isEqual:self.selected]) {
        _selected = item;
        [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid, @"show": @"detail" }];
    }
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.safeAreaRect.size.width, 60);
}

#pragma mark - CHLogicDelegate
- (void)logicChannelUpdated:(NSString *)cid {
    CHChannelModel *chan =  [CHLogic.shared.userDataSource channelWithCID:cid];
    if (chan != nil) {
        CHChannelDiffableSnapshot *snapshot = self.dataSource.snapshot;
        [snapshot reloadItemsWithIdentifiers:@[chan]];
        [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
    }
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
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
    [self fixSelectChannel];
}

#pragma mark - Action Methods
- (void)actionAddChannel:(id)sender {
    [CHRouter.shared routeTo:@"page/scan" withParams:@{ @"show": @"popover" }];
}

#pragma mark - Private Methods
- (void)fixSelectChannel {
    if (self.listView.selectionIndexes.count <= 0) {
        if (self.selected != nil) {
            NSIndexPath *indexPath = [self.dataSource indexPathForItemIdentifier:self.selected];
            if (indexPath == nil) {
                _selected = nil;
            } else {
                NSSet<NSIndexPath *> *indexPaths = [NSSet setWithObject:indexPath];
                [self.listView selectItemsAtIndexPaths:indexPaths scrollPosition:NSCollectionViewScrollPositionNone];
            }
        }
        if (self.selected == nil) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            NSSet<NSIndexPath *> *indexPaths = [NSSet setWithObject:indexPath];
            [self.listView selectItemsAtIndexPaths:indexPaths scrollPosition:NSCollectionViewScrollPositionNone];
            [self collectionView:self.listView didSelectItemsAtIndexPaths:indexPaths];
        }
    }
}


@end
