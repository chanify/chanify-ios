//
//  CHMessagesDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessagesDataSource.h"
#import "CHMessagesHeaderView.h"
#import "CHPreviewController.h"
#import "CHUnknownMsgCellConfiguration.h"
#import "CHDateCellConfiguration.h"
#import "CHUserDataSource.h"
#import "CHRouter.h"
#import "CHLogic.h"

#define kCHMessageListPageSize  16
#define kCHMessageListDateDiff  300

@interface CHMessagesDataSource ()

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, nullable, strong) CHMessagesHeaderView *headerView;
@property (nonatomic, readonly, weak) UICollectionView *collectionView;

@end

@implementation CHMessagesDataSource

typedef NSDiffableDataSourceSnapshot<NSString *, CHCellConfiguration *> CHConversationDiffableSnapshot;

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid {
    return [[self.class alloc] initWithCollectionView:collectionView channelID:cid];
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid {
    _cid = cid;
    NSDictionary<NSString *, UICollectionViewCellRegistration *> *cellRegistrations = [CHCellConfiguration cellRegistrations];
    UICollectionViewCellRegistration *unknownCellRegistration = [cellRegistrations objectForKey:NSStringFromClass(CHUnknownMsgCellConfiguration.class)];
    UICollectionViewDiffableDataSourceCellProvider cellProvider = ^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, CHCellConfiguration *item) {
        UICollectionViewCellRegistration *cellRegistration = [cellRegistrations objectForKey:NSStringFromClass(item.class)];
        if (cellRegistration != nil) {
            return fixCell(collectionView, [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item]);
        }
        return fixCell(collectionView, [collectionView dequeueConfiguredReusableCellWithRegistration:unknownCellRegistration forIndexPath:indexPath item:item]);
    };
    if (self = [super initWithCollectionView:collectionView cellProvider:cellProvider]) {
        _collectionView = collectionView;
        UICollectionViewSupplementaryRegistration *supplementaryRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:CHMessagesHeaderView.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(CHMessagesHeaderView *supplementaryView, NSString *elementKind, NSIndexPath *indexPath) {
        }];
        @weakify(self);
        self.supplementaryViewProvider = ^UICollectionReusableView *(UICollectionView *collectionView, NSString *elementKind, NSIndexPath *indexPath) {
            @strongify(self);
            if (self.headerView == nil) {
                self.headerView = [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:supplementaryRegistration forIndexPath:indexPath];
                [self updateHeaderView];
            }
            return self.headerView;
        };

        CHConversationDiffableSnapshot *snapshot = [CHConversationDiffableSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@"main"]];
        [self applySnapshot:snapshot animatingDifferences:NO];
        
        [self loadLatestMessage:NO];
    }
    return self;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, 30);
    CHCellConfiguration *item = [self itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        size.height = [item calcSize:size].height;
    }
    return size;
}

- (CGSize)sizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.collectionView.bounds.size.width, 30);
}

- (void)setNeedRecalcLayoutItem:(CHCellConfiguration *)cell {
    [cell setNeedRecalcLayout];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setNeedRecalcLayout {
    CHConversationDiffableSnapshot *snapshot = self.snapshot;
    for (CHCellConfiguration *cell in snapshot.itemIdentifiers) {
        [cell setNeedRecalcLayout];
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)scrollViewDidScroll {
    if (self.headerView != nil && self.headerView.status == CHMessagesHeaderStatusNormal) {
        self.headerView.status = CHMessagesHeaderStatusLoading;
        @weakify(self);
        dispatch_main_after(1, ^{
            @strongify(self);
            [self loadEarlistMessage];
        });
    }
}

- (void)loadEarlistMessage {
    if ([self.collectionView numberOfItemsInSection:0] <= 0) {
        [self loadLatestMessage:YES];
    } else {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:item.mid to:@"" count:kCHMessageListPageSize];
        self.headerView.status = (items.count < kCHMessageListPageSize ? CHMessagesHeaderStatusFinish : CHMessagesHeaderStatusNormal);
        if (items.count > 0) {
            NSMutableArray<CHCellConfiguration *> *selectedCells = nil;
            if (self.isEditing) {
                NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
                if (indexPaths.count > 0) {
                    selectedCells = [NSMutableArray arrayWithCapacity:indexPaths.count];
                    for (NSIndexPath *indexPath in indexPaths) {
                        [selectedCells addObject:[self itemIdentifierForIndexPath:indexPath]];
                    }
                }
            }
            [self performAndKeepOffset:^{
                NSArray<CHCellConfiguration *> *cells = [self calcItems:items last:nil];
                CHConversationDiffableSnapshot *snapshot = self.snapshot;
                [snapshot insertItemsWithIdentifiers:cells beforeItemWithIdentifier:item];
                [self applySnapshot:snapshot animatingDifferences:NO];
            }];
            if (selectedCells.count > 0) {
                for (CHCellConfiguration *cell in selectedCells) {
                    [self.collectionView selectItemAtIndexPath:[self indexPathForItemIdentifier:cell] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                }
            }
        }
    }
}

- (void)loadLatestMessage:(BOOL)animated {
    NSDate *last = nil;
    NSString *to = @"";
    NSString *from = @"7FFFFFFFFFFFFFFF";
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForRow:count - 1 inSection:0]];
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

- (void)deleteMessage:(nullable CHMessageModel *)model animated:(BOOL)animated {
    if (model != nil) {
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        CHCellConfiguration *item = [CHCellConfiguration cellConfiguration:model];
        NSMutableArray<CHCellConfiguration *> *deleteItems = [NSMutableArray arrayWithObject:item];
        NSInteger idx = [snapshot indexOfItemIdentifier:item];
        if (idx > 0) {
            NSArray<CHCellConfiguration *> *items = snapshot.itemIdentifiers;
            CHCellConfiguration *prev = [items objectAtIndex:idx - 1];
            if ([prev isKindOfClass:CHDateCellConfiguration.class]) {
                if (idx + 1 >= items.count) {
                    [deleteItems addObject:prev];
                } else {
                    CHCellConfiguration *next = [items objectAtIndex:idx + 1];
                    if ([next isKindOfClass:CHDateCellConfiguration.class]) {
                        [deleteItems addObject:prev];
                    }
                }
            }
        }
        [snapshot deleteItemsWithIdentifiers:deleteItems];
        [self applySnapshot:snapshot animatingDifferences:animated];
    }
}

- (void)deleteMessages:(NSArray<NSString *> *)mids animated:(BOOL)animated {
    if (mids.count > 0) {
        CHCellConfiguration *last = nil;
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        NSMutableArray<CHCellConfiguration *> *deleteItems = [NSMutableArray arrayWithCapacity:mids.count];
        for (CHCellConfiguration *cell in snapshot.itemIdentifiers) {
            if ([cell isKindOfClass:CHDateCellConfiguration.class]) {
                if (last != nil) {
                    [deleteItems addObject:last];
                }
                last = cell;
            } else {
                if ([mids containsObject:cell.mid]) {
                    [deleteItems addObject:cell];
                } else {
                    last = nil;
                }
            }
        }
        if (last != nil) {
            [deleteItems addObject:last];
        }
        [snapshot deleteItemsWithIdentifiers:deleteItems];
        [self applySnapshot:snapshot animatingDifferences:animated];
    }
}

- (void)previewImageWithMID:(NSString *)mid {
    NSInteger idx = 0;
    NSInteger selected = 0;
    NSMutableArray<CHPreviewItem *> *items = [NSMutableArray new];
    CHWebObjectManager *webImageManager = CHLogic.shared.webImageManager;
    for (CHCellConfiguration *cell in self.snapshot.itemIdentifiers) {
        NSString *thumbnailUrl = cell.mediaThumbnailURL;
        if (thumbnailUrl.length > 0) {
            NSURL *url = [webImageManager localFileURL:thumbnailUrl];
            if (url != nil) {
                CHPreviewItem *item = [CHPreviewItem itemWithURL:url title:cell.date.mediumFormat uti:@"public.jpeg"];
                [items addObject:item];
                if ([cell.mid isEqualToString:mid]) {
                    selected = idx;
                }
                idx++;
            }
        }
    }
    if (items.count > 0) {
        CHPreviewController *vc = [CHPreviewController previewImages:items selected:selected];
        [CHRouter.shared presentSystemViewController:vc animated:YES];
    }
}

- (void)selectItemWithIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) {
        CHCellConfiguration *cell = [self itemIdentifierForIndexPath:indexPath];
        if (![cell isKindOfClass:CHDateCellConfiguration.class]) {
            return;
        }
    }
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (NSArray<NSString *> *)selectedItemMIDs {
    NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
    NSMutableArray<NSString *> *mids = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        CHCellConfiguration *cell = [self itemIdentifierForIndexPath:indexPath];
        if (![cell isKindOfClass:CHDateCellConfiguration.class]) {
            [mids addObject:cell.mid];
        }
    }
    return mids;
}

- (void)beginEditingWiuthItem:(CHCellConfiguration *)cell {
    id delegate = self.collectionView.delegate;
    if ([delegate conformsToProtocol:@protocol(CHMessagesDataSourceDelegate)]) {
        NSIndexPath *indexPath = [self indexPathForItemIdentifier:cell];
        [(id<CHMessagesDataSourceDelegate>)delegate messagesDataSourceBeginEditing:self indexPath:indexPath];
    }
}

- (BOOL)isEditing {
    return self.collectionView.isEditing;
}

#pragma mark - Private Methods
- (void)updateHeaderView {
    if (self.headerView != nil && self.headerView.status != CHMessagesHeaderStatusLoading) {
        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] < kCHMessageListPageSize ? CHMessagesHeaderStatusFinish : CHMessagesHeaderStatusNormal);
    }
}

- (void)scrollToBottom:(BOOL)animated {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        [self.collectionView layoutIfNeeded];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
    }
}

- (void)performAndKeepOffset:(void (NS_NOESCAPE ^)(void))actions {
    CGPoint offset = self.collectionView.contentOffset;
    [self.collectionView setContentOffset:offset animated:NO];
    CGFloat height = self.collectionView.contentSize.height;
    if (actions != NULL) {
        [UIView performWithoutAnimation:actions];
    }
    [self.collectionView layoutIfNeeded];
    offset.y += self.collectionView.contentSize.height - height;
    [self.collectionView setContentOffset:offset animated:NO];
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

static inline UICollectionViewCell *fixCell(UICollectionView *collectionView, UICollectionViewCell *cell) {
    UIView *contentView = cell.contentView;
    if ([contentView isKindOfClass:CHMsgCellContentView.class]) {
        id source = collectionView.dataSource;
        if ([source isKindOfClass:CHMessagesDataSource.class]) {
            [(CHMsgCellContentView *)contentView setSource:collectionView.dataSource];
        }
    }
    return cell;
}


@end
