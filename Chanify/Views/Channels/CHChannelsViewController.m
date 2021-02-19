//
//  CHChannelsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelsViewController.h"
#import <Masonry/Masonry.h>
#import "CHChannelConfiguration.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHRouter.h"
#import "CHTheme.h"
#import "CHLogic.h"

typedef UICollectionViewDiffableDataSource<NSString *, CHChannelModel *> CHChannelDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHChannelModel *> CHChannelDiffableSnapshot;

@interface CHChannelsViewController () <UICollectionViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) UICollectionView *listView;
@property (nonatomic, readonly, strong) CHChannelDataSource *dataSource;

@end

@implementation CHChannelsViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CHTheme *theme = CHTheme.shared;

    NSArray *actions = @[
        [UIAction actionWithTitle:@"Scan QR Code".localized image:[UIImage systemImageNamed:@"qrcode.viewfinder"] identifier:@"scan" handler:^(UIAction *action) {
            [CHRouter.shared routeTo:@"/page/scan"];
        }],
        [UIAction actionWithTitle:@"New Channel".localized image:[UIImage systemImageNamed:@"plus"] identifier:@"new" handler:^(UIAction *action) {
            [CHRouter.shared routeTo:@"/page/channel/new"];
        }]
    ];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithPrimaryAction:actions[0]];
    barItem.menu = [UIMenu menuWithChildren:actions];
    self.navigationItem.rightBarButtonItem = barItem;

    UICollectionView *listView = [UICollectionView collectionListViewWithHeight:70];
    [self.view addSubview:(_listView = listView)];
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    listView.backgroundColor = theme.groupedBackgroundColor;
    listView.delegate = self;

    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell *cell, NSIndexPath *indexPath, CHChannelModel *item) {
        cell.contentConfiguration = [CHChannelConfiguration cellConfiguration:item];
    }];
    _dataSource = [[CHChannelDataSource alloc] initWithCollectionView:listView cellProvider:^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, CHChannelConfiguration *item) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
    }];
    
    [self reloadChannels];
    
    [CHLogic.shared addDelegate:self];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    CHChannelModel *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid }];
}

#pragma mark - CHLogicDelegate
- (void)logicChannelUpdated:(NSString *)cid {
    // TODO: update channel
    [self reloadChannels];
}

- (void)logicChannelsUpdated:(NSArray<NSNumber *> *)cids {
    [self reloadChannels];
}

- (void)logicMessagesUpdated:(NSArray<NSNumber *> *)mids {
    CHUserDataSource *usrDS = CHLogic.shared.userDataSource;
    [self.dataSource snapshotForSection:@"main"];
    
    CHChannelDiffableSnapshot *snapshot = self.dataSource.snapshot;
    NSArray<CHChannelModel *> *items = [snapshot itemIdentifiersInSectionWithIdentifier:@"main"];
    NSHashTable *reloadItems = [NSHashTable weakObjectsHashTable];
    for (NSNumber *m in mids) {
        uint64_t mid = m.unsignedLongLongValue;
        CHMessageModel *model = [usrDS messageWithMID:mid];
        NSString *cid = model.channel.base64;
        for (CHChannelModel *c in items) {
            if ([c.cid isEqualToString:cid]) {
                c.mid = mid;
                [reloadItems addObject:c];
                break;
            }
        }
    }
    if (reloadItems.count != 1 || reloadItems.anyObject != items.firstObject) {
        // TODO: sort items
        [snapshot deleteSectionsWithIdentifiers:@[@"main"]];
        [snapshot appendSectionsWithIdentifiers:@[@"main"]];
        [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(messageCompare:)]];
    }
    [snapshot reloadItemsWithIdentifiers:reloadItems.allObjects];
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
}

#pragma mark - Private Methods
- (void)reloadChannels {
    NSArray<CHChannelModel *> *items = [CHLogic.shared.userDataSource loadChannels];
    CHChannelDiffableSnapshot *snapshot = [CHChannelDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(messageCompare:)]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}


@end
