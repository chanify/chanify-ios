//
//  CHNodesView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHNodesView.h"
#import "CHUserDataSource.h"
#import "CHCollectionView.h"
#import "CHNodeCellView.h"
#import "CHScrollView.h"
#import "CHRouter.h"
#import "CHTheme.h"
#import "CHLogic.h"

static NSString *const cellIdentifier = @"CHNodeCellView";

typedef NSCollectionViewDiffableDataSource<NSString *, CHNodeModel *> CHNodeDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHNodeModel *> CHNodeDiffableSnapshot;

@interface CHNodesView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHNodeDataSource *dataSource;
@property (nonatomic, nullable, strong) CHNodeModel *selected;

@end

@implementation CHNodesView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _selected = nil;

        CHTheme *theme = CHTheme.shared;
        self.backgroundColor = theme.groupedBackgroundColor;
        self.rightBarButtonItem = [CHBarButtonItem itemWithIcon:@"plus.circle" target:self action:@selector(actionAddNode:)];
        
        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 1;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        [listView registerClass:CHNodeCellView.class forItemWithIdentifier:cellIdentifier];
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
        _dataSource = [[CHNodeDataSource alloc] initWithCollectionView:listView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView * collectionView, NSIndexPath * indexPath, CHNodeModel * model) {
            CHNodeCellView *item = [collectionView makeItemWithIdentifier:cellIdentifier forIndexPath:indexPath];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadData];
}

- (void)reloadData {
    CHNodeDiffableSnapshot *snapshot = [CHNodeDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[CHLogic.shared.userDataSource loadNodes]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
    [self fixSelectNode];
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    CHNodeModel *item = [self.dataSource itemIdentifierForIndexPath:indexPaths.anyObject];
    if (item != nil && ![item isEqual:self.selected]) {
        _selected = item;
        [CHRouter.shared routeTo:@"/page/node" withParams:@{ @"nid": item.nid, @"show": @"detail" }];
    }
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.safeAreaRect.size.width, 50);
}

#pragma mark - CHLogicDelegate
- (void)logicNodeUpdated:(NSString *)nid {
    CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:nid];
    if (node != nil) {
        [self reloadData];
        CHNodeDiffableSnapshot *snapshot = self.dataSource.snapshot;
        [snapshot reloadItemsWithIdentifiers:@[node]];
        [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
    }
}

- (void)logicNodesUpdated:(NSArray<NSString *> *)nids {
    [self reloadData];
}

#pragma mark - Action Methods
- (void)actionAddNode:(id)sender {
    [CHRouter.shared routeTo:@"page/node/new" withParams:@{ @"show": @"present" }];
}

#pragma mark - Private Methods
- (void)fixSelectNode {
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
