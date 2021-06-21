//
//  CHDashboardViewController.m
//  iOS
//
//  Created by WizJin on 2021/6/21.
//

#import "CHDashboardViewController.h"
#import <Masonry/Masonry.h>
#import "CHPanelCellConfiguration.h"
#import "CHPanelCollectionViewCell.h"
#import "CHTheme.h"

typedef UICollectionViewDiffableDataSource<NSString *, CHPanelCellConfiguration *> CHDashboardDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHPanelCellConfiguration *> CHDashboardDiffableSnapshot;
typedef NSDiffableDataSourceTransaction<NSString *, CHPanelCellConfiguration *> CHDashboardDiffableTransaction;

@interface CHCollectionViewDashboardLayout : UICollectionViewFlowLayout
@end

@implementation CHCollectionViewDashboardLayout

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self fixLayoutAttributes:attributes];
    return attributes;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *attributeList = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes *attributes in attributeList) {
        [self fixLayoutAttributes:attributes];
    }
    return attributeList;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForInteractivelyMovingItemAtIndexPath:(NSIndexPath *)indexPath withTargetPosition:(CGPoint)position {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForInteractivelyMovingItemAtIndexPath:indexPath withTargetPosition:position];
    attributes.alpha = 0.9;
    return attributes;
}

#pragma mark - Private Methods
- (void)fixLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (attributes.frame.origin.x >= self.sectionInset.left && attributes.frame.origin.x*2 < self.collectionView.frame.size.width) {
        CGRect frame = attributes.frame;
        frame.origin.x = self.sectionInset.left;
        attributes.frame = frame;
    }
}

@end

@interface CHDashboardViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readonly, strong) UICollectionView *collectionView;
@property (nonatomic, readonly, strong) CHDashboardDataSource *dataSource;
@property (nonatomic, readonly, strong) UILongPressGestureRecognizer *reorderGestureRecognizer;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSIndexPath *, NSIndexPath *> *movedIndexPaths;

@end

@implementation CHDashboardViewController

- (instancetype)init {
    if (self = [super init]) {
        _movedIndexPaths = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [self.collectionView removeGestureRecognizer:self.reorderGestureRecognizer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCreate:)];
    
    @weakify(self);
    CHCollectionViewDashboardLayout *layout = [CHCollectionViewDashboardLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.view addSubview:(_collectionView = collectionView)];
    collectionView.alwaysBounceVertical = YES;
    collectionView.allowsSelection = NO;
    collectionView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    collectionView.delegate = self;
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    UICollectionViewCellRegistration *registration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(CHPanelCollectionViewCell *cell, NSIndexPath *indexPath, CHPanelCellConfiguration *item) {
        cell.contentConfiguration = item;
    }];
    _dataSource = [[CHDashboardDataSource alloc] initWithCollectionView:collectionView cellProvider:^CHPanelCollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, CHPanelCellConfiguration *item) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:registration forIndexPath:indexPath item:item];
    }];
    self.dataSource.reorderingHandlers.canReorderItemHandler = ^BOOL(CHPanelCellConfiguration *configuration) {
        return YES;
    };
    self.dataSource.reorderingHandlers.willReorderHandler = ^(CHDashboardDiffableTransaction *transaction) {
        @strongify(self);
        [self.movedIndexPaths removeAllObjects];
    };

    UILongPressGestureRecognizer *reorderGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionReorder:)];
    [self.collectionView addGestureRecognizer:(_reorderGestureRecognizer = reorderGestureRecognizer)];

    NSMutableArray<CHPanelCellConfiguration *> *items = [NSMutableArray new];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"1"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"2"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"4"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"3"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"6"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"5"]];
    
    CHDashboardDiffableSnapshot *snapshot = [CHDashboardDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)originalIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath {
    if (originalIndexPath.section != proposedIndexPath.section) {
        return originalIndexPath;
    }
    if (originalIndexPath.item == proposedIndexPath.item) {
        return proposedIndexPath;
    }
    NSIndexPath *originalCurrent = [self.movedIndexPaths objectForKey:originalIndexPath];
    NSIndexPath *proposedCurrent = [self.movedIndexPaths objectForKey:proposedIndexPath];
    [self.movedIndexPaths setObject:(proposedCurrent ?: proposedIndexPath) forKey:originalIndexPath];
    [self.movedIndexPaths setObject:(originalCurrent ?: originalIndexPath) forKey:proposedIndexPath];
    return proposedIndexPath;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    indexPath = [self.movedIndexPaths objectForKey:indexPath] ?: indexPath;
    CHPanelCellConfiguration *cell = [self.dataSource itemIdentifierForIndexPath:indexPath];
    CGFloat width = self.collectionView.frame.size.width;
    if ([cell.code integerValue]%2 == 0) {
        return CGSizeMake(width * 0.48, 120);
    }
    return CGSizeMake(width, 120);
}

#pragma mark - Action Methods
- (void)actionCreate:(id)sender {
    
}

- (void)actionReorder:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            if (indexPath) {
                [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
            [self.collectionView updateInteractiveMovementTargetPosition:[gestureRecognizer locationInView:self.collectionView]];
            break;
        case UIGestureRecognizerStateEnded:
            [self.collectionView endInteractiveMovement];
            break;
        default:
            [self.collectionView cancelInteractiveMovement];
            break;
    }
}


@end
