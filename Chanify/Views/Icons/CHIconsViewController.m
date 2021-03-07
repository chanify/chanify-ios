//
//  CHIconsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHIconsViewController.h"
#import <Masonry/Masonry.h>
#import "CHIconConfiguration.h"
#import "CHIconView.h"
#import "CHTheme.h"

typedef UICollectionViewDiffableDataSource<NSString *, NSString *> CHIconDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSString *> CHIconDiffableSnapshot;

@interface CHIconsViewController () <UICollectionViewDelegate>

@property (nonatomic, readonly, strong) NSString *iconImage;
@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) UICollectionView *listView;
@property (nonatomic, readonly, strong) CHIconDataSource *dataSource;
@property (nonatomic, readonly, strong) NSArray<NSString *> *icons;

@end

@implementation CHIconsViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _icons = @[];
        _iconImage = [params valueForKey:@"icon"] ?: @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Icon".localized;
    
    self.view.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    
    UIView *panel = [UIView new];
    [self.view addSubview:panel];
    [panel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.height.equalTo(self.view.mas_height).multipliedBy(0.5);
        make.left.right.equalTo(self.view);
    }];
    
    CHIconView *iconView = [CHIconView new];
    [panel addSubview:(_iconView = iconView)];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(panel);
        make.size.mas_equalTo(CGSizeMake(128, 128));
    }];
    iconView.image = self.iconImage;

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 10;
    UICollectionView *listView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.view addSubview:(_listView = listView)];
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(panel.mas_bottom);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.right.equalTo(self.view);
    }];
    listView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    listView.alwaysBounceHorizontal = YES;
    listView.pagingEnabled = YES;
    listView.delegate = self;

    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(UICollectionViewCell *cell, NSIndexPath *indexPath, NSString *item) {
        cell.contentConfiguration = [CHIconConfiguration configurationWithIcon:item tintColor:UIColor.whiteColor];
    }];
    _dataSource = [[CHIconDataSource alloc] initWithCollectionView:listView cellProvider:^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, NSString *item) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
    }];

    CHIconDiffableSnapshot *snapshot = [CHIconDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    [snapshot appendItemsWithIdentifiers:@[@""]];
    [snapshot appendItemsWithIdentifiers:self.icons];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    self.iconView.image = [self.dataSource itemIdentifierForIndexPath:indexPath];
}


@end
