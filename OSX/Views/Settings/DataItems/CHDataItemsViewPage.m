//
//  CHDataItemsViewPage.m
//  OSX
//
//  Created by WizJin on 2021/10/6.
//

#import "CHDataItemsViewPage.h"
#import <Masonry/Masonry.h>
#import "CHWebCacheManager.h"
#import "CHDataItemCellView.h"
#import "CHCollectionView.h"
#import "CHLoadMoreView.h"
#import "CHScrollView.h"
#import "CHRouter.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

@interface CHDataItemsViewPage () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHScrollViewDelegate>

@property (nonatomic, readonly, weak) CHWebCacheManager *manager;
@property (nonatomic, readonly, strong) Class cellClass;
@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, nullable, strong) CHLoadMoreView *footerView;
@property (nonatomic, readonly, strong) CHDataListDataSource *dataSource;
@property (nonatomic, readonly, strong) NSDirectoryEnumerator *enumerator;

@end

@implementation CHDataItemsViewPage

- (instancetype)initWithCellClass:(Class)clz manager:(CHWebCacheManager *)manager {
    if (self = [super init]) {
        _name = @"";
        _pageSize = 10;
        _cellClass = clz;
        _manager = manager;
        _enumerator = self.manager.fileEnumerator;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CHTheme *theme = CHTheme.shared;

    self.backgroundColor = theme.backgroundColor;
    self.title = @"Token blocklist".localized;
    
    NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
    layout.minimumLineSpacing = 1;
    CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
    _listView = listView;
    [listView registerClass:CHDataItemCellView.class forItemWithIdentifier:cellIdentifier];
    [listView registerClass:CHLoadMoreView.class forSupplementaryViewOfKind:NSCollectionElementKindSectionFooter withIdentifier:@"CHLoadMoreView"];
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
    
    [self loadMore:NO];
}

- (void)layout {
    [super layout];
    self.scrollView.frame = self.bounds;
}

#pragma mark - Subclass Methods
- (void)previewURL:(NSURL *)url atView:(CHView *)view {

}

#pragma mark - NSCollectionViewDelegate

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.safeAreaRect.size.width, 80);
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(collectionView.bounds.size.width, 30);
}

#pragma mark - CHScrollViewDelegate
- (void)scrollViewDidScroll:(CHScrollView *)scrollView {

}

#pragma mark - Private Methods
- (void)loadMore:(BOOL)animated {
    if (self.enumerator != nil) {
        CHLoadMoreView *loadMore = self.footerView;
        CHDataListDiffableSnapshot *snapshot = self.dataSource.snapshot;
        NSInteger idx = 0;
        NSMutableArray *items = [NSMutableArray new];
        for (NSURL *url in self.enumerator) {
            NSNumber *isDir = nil;
            if ([url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil] && ![isDir boolValue]) {
                [items addObject:url];
                if (++idx >= self.pageSize) {
                    break;
                }
            }
        }
        if (idx >= self.pageSize) {
            loadMore.status = CHLoadStatusNormal;
        } else {
            _enumerator = nil;
            loadMore.status = CHLoadStatusFinish;
        }
        if (snapshot.numberOfSections <= 0) {
            [snapshot appendSectionsWithIdentifiers:@[@""]];
        }
        [snapshot appendItemsWithIdentifiers:items];
        [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
    }
}


@end
