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
#import "CHRouter.h"

typedef UICollectionViewDiffableDataSource<NSString *, CHPanelCellConfiguration *> CHDashboardDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHPanelCellConfiguration *> CHDashboardDiffableSnapshot;

@interface CHCollectionViewDashboardLayout : UICollectionViewFlowLayout
@end

@implementation CHCollectionViewDashboardLayout

- (instancetype)init {
    if (self = [super init]) {
        CGFloat margin = 8;
        self.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
        self.minimumInteritemSpacing = margin;
        self.minimumLineSpacing = margin;
    }
    return self;
}

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

#pragma mark - Private Methods
- (void)fixLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (attributes.frame.origin.x >= self.sectionInset.left && attributes.frame.origin.x*2 < self.collectionView.frame.size.width) {
        CGRect frame = attributes.frame;
        frame.origin.x = self.sectionInset.left;
        attributes.frame = frame;
    }
}

@end

@interface CHDashboardViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate>

@property (nonatomic, readonly, strong) UICollectionView *collectionView;
@property (nonatomic, readonly, strong) CHDashboardDataSource *dataSource;

@end

@implementation CHDashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCreate:)];

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[CHCollectionViewDashboardLayout new]];
    [self.view addSubview:(_collectionView = collectionView)];
    collectionView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    collectionView.alwaysBounceVertical = YES;
    collectionView.allowsSelection = YES;
    collectionView.allowsMultipleSelection = NO;
    collectionView.dragInteractionEnabled = YES;
    collectionView.dragDelegate = self;
    collectionView.dropDelegate = self;
    collectionView.delegate = self;
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    UICollectionViewCellRegistration *registration = [UICollectionViewCellRegistration registrationWithCellClass:CHPanelCollectionViewCell.class configurationHandler:^(CHPanelCollectionViewCell *cell, NSIndexPath *indexPath, CHPanelCellConfiguration *item) {
        cell.contentConfiguration = item;
    }];
    _dataSource = [[CHDashboardDataSource alloc] initWithCollectionView:collectionView cellProvider:^CHPanelCollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, CHPanelCellConfiguration *item) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:registration forIndexPath:indexPath item:item];
    }];

    NSMutableArray<CHPanelCellConfiguration *> *items = [NSMutableArray new];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"1"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"2"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"4"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"3"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"5"]];
    [items addObject:[CHPanelCellConfiguration cellConfiguration:@"6"]];

    CHDashboardDiffableSnapshot *snapshot = [CHDashboardDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [CHRouter.shared routeTo:@"/page/panel" withParams:@{ @"show": @"detail", @"code": [[self.dataSource itemIdentifierForIndexPath:indexPath] code] }];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(CHCollectionViewDashboardLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CHPanelCellConfiguration *cell = [self.dataSource itemIdentifierForIndexPath:indexPath];
    CGFloat width = self.collectionView.frame.size.width - collectionViewLayout.sectionInset.left - collectionViewLayout.sectionInset.right;
    if (cell.code.integerValue%2 == 0) {
        return CGSizeMake((width - collectionViewLayout.minimumInteritemSpacing)/2, 120);
    }
    return CGSizeMake(width, 120);
}

#pragma mark - UICollectionViewDragDelegate
- (NSArray<UIDragItem *> *)collectionView:(UICollectionView *)collectionView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    CHPanelCellConfiguration *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:item.code];
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    dragItem.localObject = item;
    return @[dragItem];
}

- (UIDragPreviewParameters *)collectionView:(UICollectionView *)collectionView dragPreviewParametersForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIDragPreviewParameters *parameters = [UIDragPreviewParameters new];
    parameters.visiblePath = [UIBezierPath bezierPathWithRoundedRect:cell.bounds cornerRadius:cell.backgroundConfiguration.cornerRadius];
    parameters.backgroundColor = UIColor.clearColor;
    return parameters;
}

#pragma mark - UICollectionViewDropDelegate
- (void)collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(id<UICollectionViewDropCoordinator>)coordinator {
    NSIndexPath *sourceIndexPath = coordinator.items.firstObject.sourceIndexPath;
    NSIndexPath *destinationIndexPath = coordinator.destinationIndexPath;
    if (coordinator.items.count == 1 && sourceIndexPath != nil && destinationIndexPath != nil) {
        CHPanelCellConfiguration *sourceItem = coordinator.items.firstObject.dragItem.localObject;
        CHDashboardDiffableSnapshot *snapshot = self.dataSource.snapshot;
        [snapshot deleteItemsWithIdentifiers:@[sourceItem]];
        NSArray *items = snapshot.itemIdentifiers;
        if (destinationIndexPath.item == 0) {
            [snapshot insertItemsWithIdentifiers:@[sourceItem] beforeItemWithIdentifier:items.firstObject];
        } else if (destinationIndexPath.item > 0 && destinationIndexPath.item < items.count) {
            [snapshot insertItemsWithIdentifiers:@[sourceItem] beforeItemWithIdentifier:[items objectAtIndex:destinationIndexPath.item]];
        } else {
            [snapshot appendItemsWithIdentifiers:@[sourceItem]];
        }
        [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
        [coordinator dropItem:coordinator.items.firstObject.dragItem toItemAtIndexPath:destinationIndexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView canHandleDropSession:(id<UIDropSession>)session {
    return session.localDragSession != nil;
}

- (UICollectionViewDropProposal *)collectionView:(UICollectionView *)collectionView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(nullable NSIndexPath *)destinationIndexPath {
    return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationMove intent:UICollectionViewDropIntentInsertAtDestinationIndexPath];
}

#pragma mark - Action Methods
- (void)actionCreate:(id)sender {
    [CHRouter.shared routeTo:@"/page/panel/new" withParams:@{ @"show": @"detail" }];
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
