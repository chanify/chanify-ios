//
//  CHIconsViewController+OSX.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHIconsViewController.h"
#import <Masonry/Masonry.h>
#import "CHIconConfiguration.h"
#import "CHColorConfiguration.h"
#import "CHCollectionView.h"
#import "CHScrollView.h"
#import "CHIconManager.h"
#import "CHIconView.h"
#import "CHTheme.h"

typedef NSCollectionViewDiffableDataSource<NSString *, NSString *> CHIconDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSString *> CHIconDiffableSnapshot;

@interface CHIconsViewController () <NSCollectionViewDelegate>

@property (nonatomic, readonly, strong) NSString *iconImage;
@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) CHIconDataSource *shapesDataSource;
@property (nonatomic, readonly, strong) CHIconDataSource *colorsDataSource;
@property (nonatomic, readonly, strong) CHIconDataSource *bgrndsDataSource;
@property (nonatomic, readonly, strong) NSArray<CHView *> *panelViews;
@property (nonatomic, readonly, strong) CHSegmentedControl *segmentedControl;

@end

@implementation CHIconsViewController

- (instancetype)initWithIcon:(NSString *)icon {
    if (self = [super init]) {
        _iconImage = icon;
    }
    return self;
}

- (void)dealloc {
    if (self.delegate != nil) {
        [self.delegate iconChanged:self.iconView.image];
    }
}

- (CGSize)calcContentSize {
    return CGSizeMake(400, 500);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CHTheme *theme = CHTheme.shared;

    self.title = @"Icon".localized;
    
    CHView *panel = [CHView new];
    [self addSubview:panel];
    panel.backgroundColor = theme.groupedBackgroundColor;
    [panel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeLayoutGuideTop);
        make.height.equalTo(self.view.mas_height).multipliedBy(0.4);
        make.left.right.equalTo(self.view);
    }];
    
    CHIconView *iconView = [CHIconView new];
    [panel addSubview:(_iconView = iconView)];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(panel);
        make.size.mas_equalTo(CGSizeMake(128, 128));
    }];
    iconView.image = self.iconImage;
    
    CHSegmentedControl *segmentedControl = [[CHSegmentedControl alloc] initWithItems:@[@"Shape".localized, @"Color".localized, @"Background".localized]];
    [self.view addSubview:(_segmentedControl = segmentedControl)];
    [segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(panel.mas_bottom);
        make.left.right.equalTo(self.view);
    }];
    [segmentedControl addTarget:self action:@selector(actionSegmentChanged:) forControlEvents:CHControlEventValueChanged];
    
    _panelViews = @[self.shapesCollectionView, self.colorsCollectionView, self.bgrndsCollectionView];
    segmentedControl.selectedSegmentIndex = 0;
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(CHCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [collectionView deselectItemsAtIndexPaths:indexPaths];
    NSIndexPath *indexPath = indexPaths.anyObject;
    if (collectionView.tagID == 0) {
        NSString *item = [self.shapesDataSource itemIdentifierForIndexPath:indexPath];
        if (item.length <= 0) {
            self.iconView.image = @"";
        } else {
            NSURLComponents *components = [NSURLComponents componentsWithString:self.iconView.image];
            if (![components.scheme isEqualToString:@"sys"]) {
                components.scheme = @"sys";
            }
            components.host = [self.shapesDataSource itemIdentifierForIndexPath:indexPath];
            self.iconView.image = components.URL.absoluteString;
        }
    } else if (collectionView.tagID == 1) {
        NSString *item = [self.colorsDataSource itemIdentifierForIndexPath:indexPath];
        NSURLComponents *components = [NSURLComponents componentsWithString:self.iconView.image];
        components.scheme = @"sys";
        NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray new];
        for (NSURLQueryItem *itm in components.queryItems) {
            if (![itm.name isEqualToString:@"c"]) {
                [items addObject:itm];
            }
        }
        if (item.length > 0) {
            [items addObject:[NSURLQueryItem queryItemWithName:@"c" value:item]];
        }
        if (components.host.length <= 0 && items.count <= 0) {
            self.iconView.image = @"";
        } else {
            components.queryItems = (items.count > 0 ? items : nil);
            self.iconView.image = components.URL.absoluteString;
        }
    } else if (collectionView.tagID == 2) {
        NSString *item = [self.bgrndsDataSource itemIdentifierForIndexPath:indexPath];
        NSURLComponents *components = [NSURLComponents componentsWithString:self.iconView.image];
        components.scheme = @"sys";
        NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray new];
        for (NSURLQueryItem *itm in components.queryItems) {
            if (![itm.name isEqualToString:@"b"]) {
                [items addObject:itm];
            }
        }
        if (item.length > 0) {
            [items addObject:[NSURLQueryItem queryItemWithName:@"b" value:item]];
        }
        if (components.host.length <= 0 && items.count <= 0) {
            self.iconView.image = @"";
        } else {
            components.queryItems = (items.count > 0 ? items : nil);
            self.iconView.image = components.URL.absoluteString;
        }
    }
}

#pragma mark - Action Methods
- (void)actionSegmentChanged:(CHSegmentedControl *)segment {
    NSInteger selected = segment.selectedSegmentIndex;
    for (NSInteger i = 0; i < self.panelViews.count; i++) {
        [[self.panelViews objectAtIndex:i] setHidden:(selected != i ? YES : NO)];
    }
}

#pragma mark - Private Methods
- (CHView *)shapesCollectionView {
    NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
    layout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    layout.sectionInset = NSEdgeInsetsMake(10, 10, 10, 10);
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 10;

    CHCollectionView *shapesView = [[CHCollectionView alloc] initWithLayout:layout];
    shapesView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    shapesView.selectable = YES;
    shapesView.delegate = self;
    shapesView.tagID = 0;

    CHScrollView *scrollView = [CHScrollView new];
    [self addSubview:scrollView];
    scrollView.documentView = shapesView;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.bottom.equalTo(self.view.mas_safeLayoutGuideBottom);
        make.left.right.equalTo(self.view);
    }];
    
    CHCollectionViewCellRegistration *cellRegistration = [CHCollectionViewCellRegistration registrationWithCellClass:CHCollectionViewCell.class configurationHandler:^(CHCollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
        NSString *icon = (item.length > 0 ? [@"sys://" stringByAppendingString:item] : @"");
        cell.contentConfiguration = [CHIconConfiguration configurationWithIcon:icon];
    }];
    _shapesDataSource = [[CHIconDataSource alloc] initWithCollectionView:shapesView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
        CHCollectionViewCell *cell = [collectionView makeItemWithIdentifier:cellRegistration.itemIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cellRegistration.configurationHandler(cell, indexPath, item);
        }
        return cell;
    }];
    CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    [snapshot appendItemsWithIdentifiers:CHIconManager.shared.icons];
    [self.shapesDataSource applySnapshot:snapshot animatingDifferences:NO];
    return scrollView;
}

- (CHView *)colorsCollectionView {
    NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
    layout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    layout.sectionInset = NSEdgeInsetsMake(10, 10, 10, 10);
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 10;
    CHCollectionView *colorsView = [[CHCollectionView alloc] initWithLayout:layout];
    colorsView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    colorsView.selectable = YES;
    colorsView.delegate = self;
    colorsView.tagID = 1;
    
    CHScrollView *scrollView = [CHScrollView new];
    [self addSubview:scrollView];
    scrollView.documentView = colorsView;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.bottom.equalTo(self.view.mas_safeLayoutGuideBottom);
        make.left.right.equalTo(self.view);
    }];

    CHCollectionViewCellRegistration *cellRegistration = [CHCollectionViewCellRegistration registrationWithCellClass:CHCollectionViewCell.class configurationHandler:^(CHCollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
        CHColorConfiguration *colorConfiguration = [CHColorConfiguration configurationWithColor:item];
        colorConfiguration.defaultColor = CHColor.whiteColor;
        cell.contentConfiguration = colorConfiguration;
    }];
    _colorsDataSource = [[CHIconDataSource alloc] initWithCollectionView:colorsView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
        CHCollectionViewCell *cell = [collectionView makeItemWithIdentifier:cellRegistration.itemIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cellRegistration.configurationHandler(cell, indexPath, item);
        }
        return cell;
    }];

    CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    [snapshot appendItemsWithIdentifiers:CHIconManager.shared.colors];
    [self.colorsDataSource applySnapshot:snapshot animatingDifferences:NO];

    [scrollView setHidden:YES];
    return scrollView;
}

- (CHView *)bgrndsCollectionView {
    NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
    layout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    layout.sectionInset = NSEdgeInsetsMake(10, 10, 10, 10);
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 10;
    CHCollectionView *bgrndsView = [[CHCollectionView alloc] initWithLayout:layout];
    bgrndsView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    bgrndsView.selectable = YES;
    bgrndsView.delegate = self;
    bgrndsView.tagID = 2;

    CHScrollView *scrollView = [CHScrollView new];
    [self addSubview:scrollView];
    scrollView.documentView = bgrndsView;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.bottom.equalTo(self.view.mas_safeLayoutGuideBottom);
        make.left.right.equalTo(self.view);
    }];

    CHCollectionViewCellRegistration *cellRegistration = [CHCollectionViewCellRegistration registrationWithCellClass:CHCollectionViewCell.class configurationHandler:^(CHCollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
        CHColorConfiguration *colorConfiguration = [CHColorConfiguration configurationWithColor:item];
        colorConfiguration.defaultColor = CHTheme.shared.tintColor;
        cell.contentConfiguration = colorConfiguration;
    }];
    _bgrndsDataSource = [[CHIconDataSource alloc] initWithCollectionView:bgrndsView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
        CHCollectionViewCell *cell = [collectionView makeItemWithIdentifier:cellRegistration.itemIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cellRegistration.configurationHandler(cell, indexPath, item);
        }
        return cell;
    }];

    CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    [snapshot appendItemsWithIdentifiers:CHIconManager.shared.backgroundColors];
    [self.bgrndsDataSource applySnapshot:snapshot animatingDifferences:NO];

    [scrollView setHidden:YES];
    return scrollView;
}


@end
