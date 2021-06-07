//
//  CHMsgsDataSource.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHMsgsDataSource.h"
#import "CHUserDataSource.h"
#import "CHUnknownMsgCellConfiguration.h"
#import "CHDateCellConfiguration.h"
#import "CHLogic+OSX.h"

@interface CHMsgsDataSource ()

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, readonly, weak) NSCollectionView *collectionView;

@end

@implementation CHMsgsDataSource

typedef NSDiffableDataSourceSnapshot<NSString *, CHCellConfiguration *> CHConversationDiffableSnapshot;

+ (instancetype)dataSourceWithCollectionView:(NSCollectionView *)collectionView channelID:(NSString *)cid {
    return [[self.class alloc] initWithCollectionView:collectionView channelID:cid];
}

- (instancetype)initWithCollectionView:(NSCollectionView *)collectionView channelID:(NSString *)cid {
    NSDictionary<NSString *, CHCollectionViewCellRegistration *> *cellRegistrations = [CHCellConfiguration cellRegistrations];
    loadRegistrationsToCollectionVoew(collectionView, cellRegistrations.allValues);
    CHCollectionViewCellRegistration *unknownCellRegistration = [cellRegistrations objectForKey:NSStringFromClass(CHUnknownMsgCellConfiguration.class)];
    NSCollectionViewDiffableDataSourceItemProvider cellProvider = ^NSCollectionViewItem *(NSCollectionView *collectionView, NSIndexPath *indexPath, CHCellConfiguration *item) {
        CHCollectionViewCellRegistration *cellRegistration = [cellRegistrations objectForKey:NSStringFromClass(item.class)];
        if (cellRegistration != nil) {
            return loadCell(collectionView, cellRegistration, indexPath, item);
        }
        return loadCell(collectionView, unknownCellRegistration, indexPath, item);
    };
    if (self = [super initWithCollectionView:collectionView itemProvider:cellProvider]) {
        _cid = cid;
        _collectionView = collectionView;
        [self reset:NO];
    }
    return self;
}

- (void)reset:(BOOL)animated {
    CHConversationDiffableSnapshot *snapshot = [CHConversationDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [self applySnapshot:snapshot animatingDifferences:NO];
    
    [self loadLatestMessage:animated];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, 30);
    CHCellConfiguration *item = [self itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        size.height = [item calcSize:size].height;
    }
    return size;
}

- (void)scrollViewDidScroll {
    @weakify(self);
    dispatch_main_after(kCHLoadingDuration, ^{
        @strongify(self);
        [self loadEarlistMessage];
    });
}

- (void)selectItemWithIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self.collectionView deselectItemsAtIndexPaths:indexPaths];
}


#pragma mark - Private Methods
- (void)updateHeaderView {
//    if (self.headerView != nil && self.headerView.status != CHLoadStatusLoading) {
//        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal);
//    }
}

- (void)scrollToBottom:(BOOL)animated {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        [self.collectionView layoutSubtreeIfNeeded];
        [self.collectionView scrollToItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:count-1 inSection:0]] scrollPosition:NSCollectionViewScrollPositionBottom];
    }
}

- (void)loadEarlistMessage {
    if ([self.collectionView numberOfItemsInSection:0] <= 0) {
        [self loadLatestMessage:YES];
    } else {
//        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//        NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:item.mid to:@"" count:kCHMessageListPageSize];
//        self.headerView.status = (items.count < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal);
//        if (items.count > 0) {
//            NSMutableArray<CHCellConfiguration *> *selectedCells = nil;
//            if (self.isEditing) {
//                NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
//                if (indexPaths.count > 0) {
//                    selectedCells = [NSMutableArray arrayWithCapacity:indexPaths.count];
//                    for (NSIndexPath *indexPath in indexPaths) {
//                        [selectedCells addObject:[self itemIdentifierForIndexPath:indexPath]];
//                    }
//                }
//            }
//            [self performAndKeepOffset:^{
//                NSArray<CHCellConfiguration *> *cells = [self calcItems:items last:nil];
//                CHConversationDiffableSnapshot *snapshot = self.snapshot;
//                [snapshot insertItemsWithIdentifiers:cells beforeItemWithIdentifier:item];
//                [self applySnapshot:snapshot animatingDifferences:NO];
//            }];
//            if (selectedCells.count > 0) {
//                for (CHCellConfiguration *cell in selectedCells) {
//                    [self.collectionView selectItemAtIndexPath:[self indexPathForItemIdentifier:cell] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
//                }
//            }
//        }
    }
}

- (void)loadLatestMessage:(BOOL)animated {
    NSDate *last = nil;
    NSString *to = @"";
    NSString *from = @"7FFFFFFFFFFFFFFF";
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForItem:count - 1 inSection:0]];
        to = item.mid;
        last = item.date;
    }
    NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:from to:to count:kCHMessageListPageSize];
    if (items.count > 0) {
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        [snapshot appendItemsWithIdentifiers:[self calcItems:items last:last]];
        [self applySnapshot:snapshot animatingDifferences:animated];
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self scrollToBottom:animated];
            [self updateHeaderView];
        });
    }
}

- (NSArray<CHCellConfiguration *> *)calcItems:(NSArray<CHMessageModel *> *)items last:(NSDate *)last {
    NSInteger count = items.count;
    NSMutableArray<CHCellConfiguration *> *cells = [NSMutableArray arrayWithCapacity:items.count];
    for (NSInteger index = count - 1; index >= 0; index--) {
        CHCellConfiguration *item = [CHCellConfiguration cellConfiguration:[items objectAtIndex:index]];
        if (last == nil || [item.date timeIntervalSinceDate:last] > kCHMessageListDateDiff) {
            CHCellConfiguration *itm = [CHDateCellConfiguration cellConfiguration:item.mid];
            last = itm.date;
            [cells addObject:itm];
        }
        [cells addObject:item];
    }
    return cells;
}

static inline void loadRegistrationsToCollectionVoew(NSCollectionView * collectionView, NSArray<CHCollectionViewCellRegistration *> *cellRegistrations) {
    for (CHCollectionViewCellRegistration *registration in cellRegistrations) {
        [registration registerCollectionView:collectionView];
    }
}

static inline NSCollectionViewItem* loadCell(NSCollectionView *collectionView, CHCollectionViewCellRegistration *registration, NSIndexPath *indexPath, CHCellConfiguration *item) {
    CHCollectionViewCell *cell = [collectionView makeItemWithIdentifier:registration.itemIdentifier forIndexPath:indexPath];
    registration.configurationHandler(cell, indexPath, item);
    return cell;
}


@end
