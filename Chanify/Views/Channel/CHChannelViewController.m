//
//  CHChannelViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelViewController.h"
#import <Masonry/Masonry.h>
#import "CHMessagesDataSource.h"
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHChannelViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) CHMessagesDataSource *dataSource;
@property (nonatomic, nullable, strong) UICollectionView *listView;


@end

@implementation CHChannelViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource channelWithCID:[params valueForKey:@"cid"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.model.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"⋯" style:UIBarButtonItemStylePlain target:self action:@selector(actionInfo:)];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumLineSpacing = 16;
    UICollectionView *listView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.view addSubview:(_listView = listView)];
    listView.alwaysBounceVertical = YES;
    listView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];

    listView.delegate = self;
    _dataSource = [CHMessagesDataSource dataSourceWithCollectionView:listView channelID:self.model.cid];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CHLogic.shared addDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [CHLogic.shared removeDelegate:self];
    [super viewDidDisappear:animated];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource sizeForItemAtIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return [self.dataSource sizeForHeaderInSection:section];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y <= 0) {
        [self.dataSource scrollViewDidScroll];
    }
}

#pragma mark - CHLogicDelegate
- (void)logicMessageUpdated:(NSArray<NSNumber *> *)mids {
    [self.dataSource loadLatestMessage:YES];
}

#pragma mark - Action Methods
- (void)actionInfo:(id)sender {
    [CHRouter.shared routeTo:@"/page/channel/detail" withParams:@{ @"cid": self.model.cid }];
}


@end
