//
//  CHBlocklistViewPage.m
//  OSX
//
//  Created by WizJin on 2021/10/4.
//

#import "CHBlocklistViewPage.h"
#import "CHBlockItemCellView.h"
#import "CHCollectionView.h"
#import "CHScrollView.h"
#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"CHBlockItemCellView";

typedef NSCollectionViewDiffableDataSource<NSString *, CHBlockedModel *> CHTokensDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHBlockedModel *> CHTokensDiffableSnapshot;

@interface CHBlocklistViewPage () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHTokensDataSource *dataSource;

@end

@implementation CHBlocklistViewPage

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CHTheme *theme = CHTheme.shared;
    self.backgroundColor = theme.backgroundColor;
    self.title = @"Token blocklist".localized;
    self.rightBarButtonItem = [CHBarButtonItem itemWithIcon:@"plus.circle" target:self action:@selector(actionAddToken:)];
    
    NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
    layout.minimumLineSpacing = 1;
    CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
    _listView = listView;
    [listView registerClass:CHBlockItemCellView.class forItemWithIdentifier:cellIdentifier];
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
    
    _dataSource = [[CHTokensDataSource alloc] initWithCollectionView:listView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView *collectionView, NSIndexPath *indexPath, CHBlockedModel *model) {
        CHBlockItemCellView *item = [collectionView makeItemWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (item != nil) {
            item.model = model;
        }
        return item;
    }];
    [CHLogic.shared addDelegate:self];
    [self reloadData:NO];
}

- (void)layout {
    [super layout];
    self.scrollView.frame = self.bounds;
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [collectionView deselectItemsAtIndexPaths:indexPaths];
    NSString *raw = [[self.dataSource itemIdentifierForIndexPath:indexPaths.anyObject] raw];
    if (raw.length > 0) {
        [CHPasteboard.shared copyWithName:@"Token".localized value:raw];
    }
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.safeAreaRect.size.width, 80);
}

#pragma mark - CHLogicDelegate
- (void)logicBlockedTokenChanged {
    [self reloadData:YES];
}

#pragma mark - Action Methods
- (void)actionAddToken:(id)sender {
    [CHRouter.shared routeTo:@"/page/block_token" withParams:@{ @"show": @"present" }];
}

#pragma mark - Private Methods
- (void)reloadData:(BOOL)animated {
    CHTokensDiffableSnapshot *snapshot = [CHTokensDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    NSArray<NSString *> *tokens = CHLogic.shared.blockedTokens;
    NSMutableArray<CHBlockedModel *> *items = [NSMutableArray arrayWithCapacity:tokens.count];
    for (NSString *raw in tokens) {
        [items addObject:[CHBlockedModel modelWithRaw:raw]];
    }
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
}


@end
