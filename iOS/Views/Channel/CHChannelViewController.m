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
#import "CHNavigationTitleView.h"
#import "CHBadgeView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHChannelViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CHMessagesDataSourceDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) CHMessagesDataSource *dataSource;
@property (nonatomic, nullable, strong) UICollectionView *listView;
@property (nonatomic, nullable, strong) CHBadgeView *badgeView;
@property (nonatomic, readonly, strong) UIBarButtonItem *detailButtonItem;

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
    
    CHTheme *theme = CHTheme.shared;
    
    CHNavigationTitleView *titleView = [[CHNavigationTitleView alloc] initWithNavigationController:self.navigationController];
    self.navigationItem.titleView = titleView;

    @weakify(self);
    NSArray<UIAction *> *actions = @[
        [UIAction actionWithTitle:@"Channel Detail".localized image:[UIImage systemImageNamed:@"info"] identifier:@"detail" handler:^(UIAction *action) {
            @strongify(self);
            [self actionInfo:nil];
        }],
        [UIAction actionWithTitle:@"Clear Messages".localized image:[UIImage systemImageNamed:@"trash"] identifier:@"clear" handler:^(UIAction *action) {
            @strongify(self);
            [self actionClearMessage:nil];
        }],
    ];
    UIBarButtonItem *detailButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:[UIAction actionWithTitle:@"⋯" image:nil identifier:@"primary" handler:^(UIAction *action) {
        @strongify(self);
        [self actionInfo:nil];
    }]];
    detailButtonItem.menu = [UIMenu menuWithChildren:actions];
    _detailButtonItem = detailButtonItem;

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        CHBadgeView *badgeView = [[CHBadgeView alloc] initWithFont:[CHFont boldSystemFontOfSize:10]];
        [titleView addSubview:(_badgeView = badgeView)];
        badgeView.textColor = theme.labelColor;
        badgeView.tintColor = theme.lightLabelColor;
        badgeView.backgroundColor = theme.backgroundColor;
    }

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumLineSpacing = 16;
    UICollectionView *listView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.view addSubview:(_listView = listView)];
    listView.alwaysBounceVertical = YES;
    listView.allowsSelection = NO;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.badgeView != nil) {
        CGRect bounds = self.navigationItem.titleView.bounds;
        self.badgeView.frame = CGRectMake(-20, (bounds.size.height - 20 )*0.5, 20, 20);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CHLogic.shared addReadChannel:self.model.cid];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [CHLogic.shared removeReadChannel:self.model.cid];
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
    self.listView.allowsSelection = editing;
    [self.listView setEditing:editing];
    self.badgeView.hidden = editing;
    if (editing) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionCancel:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionDelete:)];
        self.navigationItem.leftBarButtonItem.tintColor = CHTheme.shared.alertColor;
    } else {
        self.navigationItem.rightBarButtonItem = self.detailButtonItem;
        self.navigationItem.leftBarButtonItem = nil;
    }
    [super setEditing:editing animated:animated];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.dataSource selectItemWithIndexPath:indexPath];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
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
- (void)messagesDataSourceBeginEditing:(CHMessagesDataSource *)dataSource indexPath:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
    [self.listView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
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

- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids {
    [self.dataSource deleteMessages:mids animated:YES];
}

- (void)logicMessagesCleared:(NSString *)cid {
    if ([self.model.cid isEqualToString:cid]) {
        [self.dataSource reset:YES];
    }
}

- (void)logicMessagesUnreadChanged:(NSNumber *)unread {
    [self updateUnreadBadge:unread.integerValue];
}

#pragma mark - Action Methods
- (void)actionInfo:(id)sender {
    [CHRouter.shared routeTo:@"/page/channel/detail" withParams:@{ @"cid": self.model.cid }];
}

- (void)actionClearMessage:(id)sender {
    @weakify(self);
    [CHRouter.shared showAlertWithTitle:@"Delete all messages or not?".localized action:@"Delete".localized handler:^{
        @strongify(self);
        [CHRouter.shared showIndicator:YES];
        [CHLogic.shared deleteMessagesWithCID:self.model.cid];
        [CHRouter.shared showIndicator:NO];
    }];
}

- (void)actionDelete:(id)sender {
    NSArray<NSString *> *mids = self.dataSource.selectedItemMIDs;
    if (mids.count > 0) {
        @weakify(self);
        NSString *title = [NSString stringWithFormat:@"Delete %d selected messages or not?".localized, mids.count];
        [CHRouter.shared showAlertWithTitle:title action:@"Delete".localized handler:^{
            @strongify(self);
            [CHLogic.shared deleteMessages:mids];
            [self setEditing:NO animated:YES];
        }];
    }
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

- (void)updateUnreadBadge:(NSInteger)unread {
    self.badgeView.count = unread;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    [(CHNavigationTitleView *)self.navigationItem.titleView setTitle:title];
}


@end
