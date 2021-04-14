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

@interface CHChannelViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CHMessagesDataSourceDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) CHMessagesDataSource *dataSource;
@property (nonatomic, nullable, strong) UICollectionView *listView;

@end

@implementation CHChannelViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = nil;
        [self updateChannel:[params valueForKey:@"cid"]];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumLineSpacing = 16;
    UICollectionView *listView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.view addSubview:(_listView = listView)];
    listView.alwaysBounceVertical = YES;
    listView.allowsSelectionDuringEditing = YES;
    listView.allowsMultipleSelectionDuringEditing = YES;
    listView.backgroundColor = CHTheme.shared.groupedBackgroundColor;
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];

    listView.delegate = self;
    _dataSource = [CHMessagesDataSource dataSourceWithCollectionView:listView channelID:self.model.cid];
    
    [self setEditing:NO animated:NO];
    
    [CHLogic.shared addDelegate:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    @weakify(self);
    [coordinator animateAlongsideTransitionInView:self.view
    animation:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        @strongify(self);
        [self.dataSource setNeedRecalcLayout];
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (BOOL)isEqualToViewController:(CHChannelViewController *)rhs {
    return [self.model isEqual:rhs.model];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.listView setEditing:editing];
    if (editing) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionClear:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionCancel:)];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"⋯" style:UIBarButtonItemStylePlain target:self action:@selector(actionInfo:)];
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!collectionView.editing) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
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

#pragma mark - CHMessagesDataSourceDelegate
- (void)messagesDataSourceBeginEditing:(CHMessagesDataSource *)dataSource {
    [self setEditing:YES animated:YES];
}

#pragma mark - CHLogicDelegate
- (void)logicChannelUpdated:(NSString *)cid {
    [self updateChannel:cid];
}

- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids {
    // TODO: Fix recive unordered messages.
    [self.dataSource loadLatestMessage:YES];
}

- (void)logicMessageDeleted:(CHMessageModel *)model {
    [self.dataSource deleteMessage:model animated:YES];
}

#pragma mark - Action Methods
- (void)actionInfo:(id)sender {
    [CHRouter.shared routeTo:@"/page/channel/detail" withParams:@{ @"cid": self.model.cid }];
}

- (void)actionClear:(id)sender {
    
}

- (void)actionCancel:(id)sender {
    [self setEditing:NO animated:YES];
}

#pragma mark - Private Methods
- (void)updateChannel:(NSString *)cid {
    if (self.model == nil || [cid isEqualToString:self.model.cid]) {
        _model = [CHLogic.shared.userDataSource channelWithCID:cid];
        self.title = self.model.title;
    }
}


@end
