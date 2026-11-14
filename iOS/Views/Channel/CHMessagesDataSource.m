//
//  CHMessagesDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessagesDataSource.h"
#import "CHPreviewController.h"
#import "CHLoadMoreView.h"
#import "CHUnknownMsgCellConfiguration.h"
#import "CHDateCellConfiguration.h"
#import "CHMsgCellConfiguration.h"
#import "CHWebImageManager.h"
#import "CHUserDataSource.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHMessagesDataSource () <CHMessageSource>

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, copy) NSString *targetMID;
@property (nonatomic) BOOL browsingHistory;
@property (nonatomic) BOOL loadingNext;
@property (nonatomic) BOOL loadingEarlier;
@property (nonatomic) BOOL loadingLatest;
@property (nonatomic) BOOL latestRequested;
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingReceivedMIDs;
@property (nonatomic) BOOL scrollAfterLatestLoad;
@property (nonatomic) NSUInteger mutationRevision;
@property (nonatomic) BOOL loadingTarget;
@property (nonatomic) NSUInteger contextGeneration;
@property (nonatomic, nullable, strong) CHLoadMoreView *headerView;
@property (nonatomic, readonly, weak) UICollectionView *collectionView;
@property (nonatomic, nullable, weak) UIMenuController *itemMenu;
@property (nonatomic, nullable, weak) id<CHMsgCellItem> lastMsgCellItem;

@end

@implementation CHMessagesDataSource

typedef NSDiffableDataSourceSnapshot<NSString *, CHCellConfiguration *> CHConversationDiffableSnapshot;

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid {
    return [self dataSourceWithCollectionView:collectionView channelID:cid targetMID:nil];
}

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid targetMID:(NSString *)mid {
    return [[self alloc] initWithCollectionView:collectionView channelID:cid targetMID:mid];
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid targetMID:(NSString *)mid {
    _targetMID = [mid copy];
    _cid = cid;
    _lastMsgCellItem = nil;
    NSDictionary<NSString *, UICollectionViewCellRegistration *> *cellRegistrations = [CHCellConfiguration cellRegistrations];
    UICollectionViewCellRegistration *unknownCellRegistration = [cellRegistrations objectForKey:NSStringFromClass(CHUnknownMsgCellConfiguration.class)];
    UICollectionViewDiffableDataSourceCellProvider cellProvider = ^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, CHCellConfiguration *item) {
        UICollectionViewCellRegistration *cellRegistration = [cellRegistrations objectForKey:NSStringFromClass(item.class)];
        if (cellRegistration != nil) {
            return loadCell(collectionView, cellRegistration, indexPath, item);
        }
        return loadCell(collectionView, unknownCellRegistration, indexPath, item);
    };
    if (self = [super initWithCollectionView:collectionView cellProvider:cellProvider]) {
        _collectionView = collectionView;
        UICollectionViewSupplementaryRegistration *supplementaryRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:CHLoadMoreView.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(CHLoadMoreView *supplementaryView, NSString *elementKind, NSIndexPath *indexPath) {
        }];
        @weakify(self);
        self.supplementaryViewProvider = ^UICollectionReusableView *(UICollectionView *collectionView, NSString *elementKind, NSIndexPath *indexPath) {
            @strongify(self);
            CHLoadStatus status = self.headerView ? self.headerView.status :
                ([collectionView numberOfItemsInSection:0] < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal);
            // Scrolling offscreen or resetting can return the header to the reuse
            // queue. Dequeue on every request and preserve the pagination state.
            CHLoadMoreView *header = [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:supplementaryRegistration forIndexPath:indexPath];
            self.headerView = header;
            header.status = status;
            return header;
        };

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(actionDidShowMenu:) name:UIMenuControllerDidShowMenuNotification object:nil];

        [self reset:NO];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)reset:(BOOL)animated {
    self.contextGeneration++;
    self.loadingTarget = NO;
    self.loadingEarlier = NO;
    self.loadingNext = NO;
    self.loadingLatest = NO;
    self.latestRequested = NO;
    self.pendingReceivedMIDs = [NSMutableSet new];
    self.scrollAfterLatestLoad = NO;
    self.headerView.status = CHLoadStatusNormal;
    self.collectionView.backgroundView = nil;
    CHConversationDiffableSnapshot *snapshot = [CHConversationDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [self applySnapshot:snapshot animatingDifferences:NO];
    
    if (self.targetMID.length) {
        [self loadTargetMessage];
    } else {
        self.browsingHistory = NO;
        [self loadLatestMessage:animated];
    }
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

- (void)clearActivedCellItem {
    UIMenuController *menu = self.itemMenu;
    if (menu != nil) {
        self.itemMenu = nil;
        [menu hideMenu];
    }
    [self activeMsgCellItem:nil];
}

- (void)setNeedRecalcLayout {
    CHConversationDiffableSnapshot *snapshot = self.snapshot;
    for (CHCellConfiguration *cell in snapshot.itemIdentifiers) {
        [cell setNeedRecalcLayout];
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)scrollViewDidScroll {
    if (self.loadingTarget || self.loadingEarlier) return;
    if (self.headerView != nil && self.headerView.status == CHLoadStatusNormal) {
        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] > 0 ? CHLoadStatusLoading : CHLoadStatusFinish);
        NSUInteger generation = self.contextGeneration;
        @weakify(self);
        dispatch_main_after(kCHLoadingDuration, ^{
            @strongify(self);
            if (self.contextGeneration != generation) return;
            [self loadEarlistMessage];
        });
    }
}

- (void)scrollToBottom:(BOOL)animated {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        [self.collectionView layoutIfNeeded];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
    }
}

- (void)loadEarlistMessage {
    if (self.loadingTarget || self.loadingEarlier) return;
    CHCellConfiguration *anchor = self.snapshot.itemIdentifiers.firstObject;
    if (!anchor) { [self loadLatestMessage:YES]; return; }
    self.loadingEarlier = YES;
    self.headerView.status = CHLoadStatusLoading;
    NSUInteger generation = self.contextGeneration;
    NSUInteger revision = self.mutationRevision;
    CHUserDataSource *account = CHLogic.shared.userDataSource;
    __weak typeof(self) weakSelf = self;
    [account loadMessagesWithCID:self.cid from:anchor.mid to:@"" count:kCHMessageListPageSize ascending:NO completion:^(NSArray<CHMessageModel *> *items, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || generation != self.contextGeneration || account != CHLogic.shared.userDataSource) return;
        self.loadingEarlier = NO;
        if (revision != self.mutationRevision || [self.snapshot indexOfItemIdentifier:anchor] == NSNotFound) {
            [self loadEarlistMessage];
            return;
        }
        if (error) {
            self.headerView.status = CHLoadStatusNormal;
            [CHRouter.shared makeToast:@"Could not load messages. Please try again.".localized];
            return;
        }
        self.headerView.status = items.count < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal;
        if (!items.count) return;
        NSMutableArray<CHCellConfiguration *> *selectedCells = [NSMutableArray new];
        if (self.isEditing) {
            for (NSIndexPath *path in self.collectionView.indexPathsForSelectedItems) {
                CHCellConfiguration *cell = [self itemIdentifierForIndexPath:path];
                if (cell) [selectedCells addObject:cell];
            }
        }
        [self performAndKeepOffset:^{
            CHConversationDiffableSnapshot *snapshot = self.snapshot;
            [snapshot insertItemsWithIdentifiers:[self calcItems:items last:nil] beforeItemWithIdentifier:anchor];
            [self applySnapshot:snapshot animatingDifferences:NO];
        }];
        for (CHCellConfiguration *cell in selectedCells) {
            NSIndexPath *path = [self indexPathForItemIdentifier:cell];
            if (path) [self.collectionView selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }];
}

- (void)receiveMessages:(NSArray<NSString *> *)mids {
    if (self.loadingLatest || self.loadingTarget) {
        [self.pendingReceivedMIDs addObjectsFromArray:mids];
        return;
    }
    if (self.pendingReceivedMIDs.count) {
        [self.pendingReceivedMIDs addObjectsFromArray:mids];
        mids = self.pendingReceivedMIDs.allObjects;
        [self.pendingReceivedMIDs removeAllObjects];
    }
    // Forward pagination alone cannot discover a late delivery inside the
    // already loaded interval. Merge those records without resetting history.
    NSArray<CHCellConfiguration *> *current = self.snapshot.itemIdentifiers;
    NSMutableDictionary<NSString *, CHCellConfiguration *> *messages = [NSMutableDictionary new];
    for (CHCellConfiguration *cell in current) {
        if (![cell isKindOfClass:CHDateCellConfiguration.class]) messages[cell.mid] = cell;
    }
    NSArray<NSString *> *ordered = [messages.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSString *first = ordered.firstObject;
    NSString *last = ordered.lastObject;
    BOOL changed = NO;
    CHUserDataSource *account = CHLogic.shared.userDataSource;
    for (NSString *mid in mids) {
        if (!first || [mid compare:first] == NSOrderedAscending || [mid compare:last] == NSOrderedDescending || messages[mid]) continue;
        CHMessageModel *model = [account messageWithMID:mid];
        if (![model.channel.base64Code isEqualToString:self.cid]) continue;
        messages[mid] = [CHCellConfiguration cellConfiguration:model];
        changed = YES;
    }
    if (changed) {
        self.mutationRevision++;
        NSMutableArray<CHCellConfiguration *> *cells = [NSMutableArray new];
        NSDate *date = nil;
        for (NSString *mid in [messages.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
            CHCellConfiguration *cell = messages[mid];
            if (!date || [cell.date timeIntervalSinceDate:date] > kCHMessageListDateDiff) {
                [cells addObject:[CHDateCellConfiguration cellConfiguration:mid]];
                date = cell.date;
            }
            [cells addObject:cell];
        }
        NSIndexPath *anchorPath = [[self.collectionView.indexPathsForVisibleItems sortedArrayUsingSelector:@selector(compare:)] firstObject];
        CHCellConfiguration *anchor = anchorPath ? [self itemIdentifierForIndexPath:anchorPath] : nil;
        UICollectionViewLayoutAttributes *before = anchorPath ? [self.collectionView layoutAttributesForItemAtIndexPath:anchorPath] : nil;
        CGFloat anchorY = before.frame.origin.y;
        CGPoint offset = self.collectionView.contentOffset;
        [UIView performWithoutAnimation:^{
            CHConversationDiffableSnapshot *snapshot = [CHConversationDiffableSnapshot new];
            [snapshot appendSectionsWithIdentifiers:@[@"main"]];
            [snapshot appendItemsWithIdentifiers:cells];
            [self applySnapshot:snapshot animatingDifferences:NO];
            [self.collectionView layoutIfNeeded];
            NSIndexPath *path = anchor ? [self indexPathForItemIdentifier:anchor] : nil;
            UICollectionViewLayoutAttributes *after = path ? [self.collectionView layoutAttributesForItemAtIndexPath:path] : nil;
            CGPoint restored = offset;
            if (before && after) restored.y += after.frame.origin.y - anchorY;
            [self.collectionView setContentOffset:restored animated:NO];
        }];
    }
    [self loadLatestMessage:YES];
}

- (void)loadLatestMessage:(BOOL)animated {
    if (self.browsingHistory) return;
    if (self.loadingLatest) { self.latestRequested = YES; return; }
    self.loadingLatest = YES;
    CHCellConfiguration *last = self.snapshot.itemIdentifiers.lastObject;
    NSUInteger generation = self.contextGeneration;
    NSUInteger revision = self.mutationRevision;
    CHUserDataSource *account = CHLogic.shared.userDataSource;
    __weak typeof(self) weakSelf = self;
    // When catching up, load the nearest newer records so a burst cannot create a gap.
    [account loadMessagesWithCID:self.cid from:@"7FFFFFFFFFFFFFFF" to:last.mid ?: @"" count:kCHMessageListPageSize ascending:last != nil completion:^(NSArray<CHMessageModel *> *items, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || generation != self.contextGeneration || account != CHLogic.shared.userDataSource) return;
        self.loadingLatest = NO;
        BOOL requested = self.latestRequested;
        self.latestRequested = NO;
        if (revision != self.mutationRevision) { [self loadLatestMessage:animated]; return; }
        if (error) {
            [CHRouter.shared makeToast:@"Could not load messages. Please try again.".localized];
            return;
        }
        if (items.count) {
            CHConversationDiffableSnapshot *snapshot = self.snapshot;
            [snapshot appendItemsWithIdentifiers:[self calcItems:items last:last.date]];
            [self applySnapshot:snapshot animatingDifferences:animated];
            id delegate = self.collectionView.delegate;
            BOOL keepPosition = [delegate conformsToProtocol:@protocol(CHMessagesDataSourceDelegate)] && [(id<CHMessagesDataSourceDelegate>)delegate messagesDataSourceReciveNewMessage];
            if (self.scrollAfterLatestLoad || !keepPosition) [self scrollToBottom:animated];
        }
        self.scrollAfterLatestLoad = NO;
        [self updateHeaderView];
        if (self.pendingReceivedMIDs.count) [self receiveMessages:@[]];
        if (requested || (last && items.count == kCHMessageListPageSize)) [self loadLatestMessage:animated];
    }];
}

- (void)loadTargetMessage {
    if (self.loadingTarget) return;
    NSString *mid = self.targetMID;
    self.targetMID = nil;
    self.browsingHistory = YES;
    self.loadingTarget = YES;
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    [indicator startAnimating];
    self.collectionView.backgroundView = indicator;
    NSUInteger generation = self.contextGeneration;
    NSUInteger revision = self.mutationRevision;
    CHUserDataSource *account = CHLogic.shared.userDataSource;
    __weak typeof(self) weakTargetSelf = self;
    [account loadMessagesNearMID:mid channelID:self.cid count:kCHMessageListPageSize completion:^(NSArray<CHMessageModel *> *messages, NSError *error) {
        __strong typeof(weakTargetSelf) self = weakTargetSelf;
        if (!self || generation != self.contextGeneration || account != CHLogic.shared.userDataSource) return;
        self.loadingTarget = NO;
        self.collectionView.backgroundView = nil;
        if (revision != self.mutationRevision) {
            self.targetMID = mid;
            [self loadTargetMessage];
            return;
        }
        if (error) {
            self.targetMID = mid;
            UIButton *retry = [UIButton buttonWithType:UIButtonTypeSystem];
            [retry setTitle:@"Retry".localized forState:UIControlStateNormal];
            [retry addTarget:self action:@selector(retryTargetMessage:) forControlEvents:UIControlEventTouchUpInside];
            self.collectionView.backgroundView = retry;
            [CHRouter.shared makeToast:@"Could not load messages. Please try again.".localized];
            return;
        }
        BOOL found = NO;
        for (CHMessageModel *message in messages) if ([message.mid isEqualToString:mid]) found = YES;
        if (!found) {
            self.browsingHistory = NO;
            [CHRouter.shared makeToast:@"This message is no longer available".localized];
            [self loadLatestMessage:NO];
            return;
        }
        self.browsingHistory = YES;
        self.loadingTarget = YES;
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        NSArray *cells = [self calcItems:messages last:nil];
        [snapshot appendItemsWithIdentifiers:cells];
        __weak typeof(self) weakSelf = self;
        [self applySnapshot:snapshot animatingDifferences:NO completion:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || generation != self.contextGeneration) return;
            [self.collectionView layoutIfNeeded];
            for (CHCellConfiguration *item in cells) {
                if ([item.mid isEqualToString:mid] && ![item isKindOfClass:CHDateCellConfiguration.class]) {
                    NSIndexPath *path = [self indexPathForItemIdentifier:item];
                    if (!path) break;
                    [self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                    [self.collectionView layoutIfNeeded];
                    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:path];
                    UIView *highlight = [[UIView alloc] initWithFrame:cell.contentView.bounds];
                    highlight.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    highlight.backgroundColor = [UIColor.systemYellowColor colorWithAlphaComponent:0.3];
                    highlight.userInteractionEnabled = NO;
                    [cell.contentView addSubview:highlight];
                    [UIView animateWithDuration:0.5 delay:1 options:UIViewAnimationOptionCurveEaseOut animations:^{ highlight.alpha = 0; } completion:^(BOOL finished) { [highlight removeFromSuperview]; }];
                    break;
                }
            }
            self.loadingTarget = NO;
            [self updateHeaderView];
            if (self.pendingReceivedMIDs.count) [self receiveMessages:@[]];
        }];
    }];
}

- (void)retryTargetMessage:(id)sender { [self loadTargetMessage]; }

- (void)loadNextMessages {
    if (!self.browsingHistory || self.loadingNext || self.loadingTarget) return;
    CHCellConfiguration *last = self.snapshot.itemIdentifiers.lastObject;
    if (!last) return;
    self.loadingNext = YES;
    NSUInteger generation = self.contextGeneration;
    NSUInteger revision = self.mutationRevision;
    CHUserDataSource *account = CHLogic.shared.userDataSource;
    __weak typeof(self) weakSelf = self;
    [account loadMessagesWithCID:self.cid from:@"7FFFFFFFFFFFFFFF" to:last.mid count:kCHMessageListPageSize ascending:YES completion:^(NSArray<CHMessageModel *> *messages, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || generation != self.contextGeneration || account != CHLogic.shared.userDataSource) return;
        self.loadingNext = NO;
        if (revision != self.mutationRevision) { [self loadNextMessages]; return; }
        if (error) {
            [CHRouter.shared makeToast:@"Could not load messages. Please try again.".localized];
            return;
        }
        if (messages.count < kCHMessageListPageSize) self.browsingHistory = NO;
        if (messages.count) {
            CHConversationDiffableSnapshot *snapshot = self.snapshot;
            [snapshot appendItemsWithIdentifiers:[self calcItems:messages last:last.date]];
            [self applySnapshot:snapshot animatingDifferences:NO];
        }
    }];
}

- (void)showLatestMessages {
    if (self.browsingHistory) {
        self.targetMID = nil;
        [self reset:NO];
        self.scrollAfterLatestLoad = YES;
    } else if (self.loadingLatest) {
        self.scrollAfterLatestLoad = YES;
    }
    [self scrollToBottom:YES];
}

- (void)deleteMessage:(nullable CHMessageModel *)model animated:(BOOL)animated {
    if (model != nil) {
        self.mutationRevision++;
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        CHCellConfiguration *item = [CHCellConfiguration cellConfiguration:model];
        NSMutableArray<CHCellConfiguration *> *deleteItems = [NSMutableArray arrayWithObject:item];
        NSInteger idx = [snapshot indexOfItemIdentifier:item];
        if (idx == NSNotFound) return;
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
        self.mutationRevision++;
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

#pragma mark - CHMessageSource
- (void)activeMsgCellItem:(nullable id<CHMsgCellItem>)cellItem {
    id<CHMsgCellItem> lastItem = self.lastMsgCellItem;
    if (lastItem != cellItem) {
        if (lastItem != nil) {
            if ([lastItem respondsToSelector:@selector(msgCellItemWillUnactive:)]) {
                [lastItem msgCellItemWillUnactive:lastItem];
            }
            [lastItem resignFirstResponder];
        }
        self.lastMsgCellItem = cellItem;
    }
}

- (void)setNeedRecalcLayoutItem:(CHCellConfiguration *)cell {
    [cell setNeedRecalcLayout];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)beginEditingWithItem:(CHCellConfiguration *)cell {
    [self clearActivedCellItem];

    id delegate = self.collectionView.delegate;
    if ([delegate conformsToProtocol:@protocol(CHMessagesDataSourceDelegate)]) {
        NSIndexPath *indexPath = [self indexPathForItemIdentifier:cell];
        [(id<CHMessagesDataSourceDelegate>)delegate messagesDataSourceBeginEditing:self indexPath:indexPath];
    }
}

- (void)previewImageWithMID:(NSString *)mid {
    NSInteger idx = 0;
    NSInteger selected = 0;
    NSMutableArray<CHPreviewItem *> *items = [NSMutableArray new];
    CHWebImageManager *webImageManager = CHLogic.shared.webImageManager;
    for (CHCellConfiguration *cell in self.snapshot.itemIdentifiers) {
        NSString *thumbnailUrl = cell.mediaThumbnailURL;
        if (thumbnailUrl.length > 0) {
            NSURL *url = [webImageManager localFileURL:thumbnailUrl];
            if (url != nil) {
                CHPreviewItem *item = [CHPreviewItem itemWithURL:url title:cell.date.mediumFormat uti:@"image"];
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

- (BOOL)isEditing {
    return self.collectionView.isEditing;
}

#pragma mark - Action Methods
- (void)actionDidShowMenu:(NSNotification *)notification {
    self.itemMenu = notification.object;
}

#pragma mark - Private Methods
- (void)updateHeaderView {
    if (self.headerView != nil && self.headerView.status != CHLoadStatusLoading) {
        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal);
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

static inline UICollectionViewCell *loadCell(UICollectionView *collectionView, UICollectionViewCellRegistration *registration, NSIndexPath *indexPath, CHCellConfiguration *item) {
    UICollectionViewCell *cell = [collectionView dequeueConfiguredReusableCellWithRegistration:registration forIndexPath:indexPath item:item];
    UIView *contentView = cell.contentView;
    if ([contentView isKindOfClass:CHMsgCellContentView.class]) {
        id source = collectionView.dataSource;
        if ([source isKindOfClass:CHMessagesDataSource.class]) {
            [(CHMsgCellContentView *)contentView setSource:(CHMessagesDataSource *)collectionView.dataSource];
        }
    }
    return cell;
}


@end
