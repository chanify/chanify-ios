//
//  CHIconsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHIconsViewController.h"
#import <Masonry/Masonry.h>
#import "CHIconConfiguration.h"
#import "CHColorConfiguration.h"
#import "CHIconManager.h"
#import "CHIconView.h"
#import "CHTheme.h"

typedef UICollectionViewDiffableDataSource<NSString *, NSString *> CHIconDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSString *> CHIconDiffableSnapshot;

@interface CHIconsViewController () <UICollectionViewDelegate>

@property (nonatomic, readonly, strong) NSString *iconImage;
@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) UICollectionView *shapesView;
@property (nonatomic, readonly, strong) UICollectionView *colorsView;
@property (nonatomic, readonly, strong) UICollectionView *bgrndsView;
@property (nonatomic, readonly, strong) CHIconDataSource *shapesDataSource;
@property (nonatomic, readonly, strong) CHIconDataSource *colorsDataSource;
@property (nonatomic, readonly, strong) CHIconDataSource *bgrndsDataSource;
@property (nonatomic, readonly, strong) NSArray<UIView *> *panelViews;
@property (nonatomic, readonly, strong) CHSegmentedControl *segmentedControl;

@end

@implementation CHIconsViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _iconImage = [params valueForKey:@"icon"] ?: @"";
    }
    return self;
}

- (instancetype)initWithIcon:(NSString *)icon {
    return [self initWithParameters:@{ @"icon": icon }];
}

- (void)dealloc {
    if (self.delegate != nil) {
        [self.delegate iconChanged:self.iconView.image];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CHTheme *theme = CHTheme.shared;

    self.title = @"Icon".localized;
    
    UIView *panel = [UIView new];
    [self.view addSubview:panel];
    panel.backgroundColor = theme.groupedBackgroundColor;
    [panel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
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
        make.height.mas_equalTo(40);
    }];
    [segmentedControl addTarget:self action:@selector(actionSegmentChanged:) forControlEvents:UIControlEventValueChanged];

    _panelViews = @[self.shapesCollectionView, self.colorsCollectionView, self.bgrndsCollectionView];
    NSInteger i = 0;
    for (UIView *view in self.panelViews) {
        view.tagID = i++;
    }
    segmentedControl.selectedSegmentIndex = 0;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
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
- (UICollectionView *)shapesCollectionView {
    if (_shapesView == nil) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 10;
        UICollectionView *shapesView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [self.view addSubview:(_shapesView = shapesView)];
        [shapesView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.segmentedControl.mas_bottom);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.left.right.equalTo(self.view);
        }];
        shapesView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        shapesView.alwaysBounceHorizontal = YES;
        shapesView.pagingEnabled = YES;
        shapesView.delegate = self;

        UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(UICollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
            NSString *icon = (item.length > 0 ? [@"sys://" stringByAppendingString:item] : @"");
            cell.contentConfiguration = [CHIconConfiguration configurationWithIcon:icon];
        }];
        _shapesDataSource = [[CHIconDataSource alloc] initWithCollectionView:shapesView cellProvider:^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
            return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
        }];

        CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@""]];
        [snapshot appendItemsWithIdentifiers:CHIconManager.shared.icons];
        [self.shapesDataSource applySnapshot:snapshot animatingDifferences:NO];
    }
    return _shapesView;
}

- (UICollectionView *)colorsCollectionView {
    if (_colorsView == nil) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 10;
        UICollectionView *colorsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [self.view addSubview:(_colorsView = colorsView)];
        [colorsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.segmentedControl.mas_bottom);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.left.right.equalTo(self.view);
        }];
        colorsView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        colorsView.alwaysBounceHorizontal = YES;
        colorsView.pagingEnabled = YES;
        colorsView.delegate = self;
        [colorsView setHidden:YES];

        UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(UICollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
            CHColorConfiguration *colorConfiguration = [CHColorConfiguration configurationWithColor:item];
            colorConfiguration.defaultColor = UIColor.whiteColor;
            cell.contentConfiguration = colorConfiguration;
        }];
        _colorsDataSource = [[CHIconDataSource alloc] initWithCollectionView:colorsView cellProvider:^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
            return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
        }];

        CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@""]];
        [snapshot appendItemsWithIdentifiers:CHIconManager.shared.colors];
        [self.colorsDataSource applySnapshot:snapshot animatingDifferences:NO];
    }
    return _colorsView;
}

- (UICollectionView *)bgrndsCollectionView {
    if (_bgrndsView == nil) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 10;
        UICollectionView *bgrndsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [self.view addSubview:(_bgrndsView = bgrndsView)];
        [bgrndsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.segmentedControl.mas_bottom);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.left.right.equalTo(self.view);
        }];
        bgrndsView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        bgrndsView.alwaysBounceHorizontal = YES;
        bgrndsView.pagingEnabled = YES;
        bgrndsView.delegate = self;
        [bgrndsView setHidden:YES];

        UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(UICollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
            CHColorConfiguration *colorConfiguration = [CHColorConfiguration configurationWithColor:item];
            colorConfiguration.defaultColor = CHTheme.shared.tintColor;
            cell.contentConfiguration = colorConfiguration;
        }];
        _bgrndsDataSource = [[CHIconDataSource alloc] initWithCollectionView:bgrndsView cellProvider:^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
            return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
        }];

        CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@""]];
        [snapshot appendItemsWithIdentifiers:CHIconManager.shared.backgroundColors];
        [self.bgrndsDataSource applySnapshot:snapshot animatingDifferences:NO];
    }
    return _bgrndsView;
}


@end
