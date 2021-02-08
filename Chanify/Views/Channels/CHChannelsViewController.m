//
//  CHChannelsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelsViewController.h"
#import <Masonry/Masonry.h>
#import "CHChannelCell.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHRouter.h"
#import "CHTheme.h"
#import "CHLogic.h"

static NSString *const cellIdentifier = @"CHChannelCell";

@interface CHChannelsViewController () <UICollectionViewDelegate, UICollectionViewDataSource, CHLogicDelegate>

@property (nonatomic, readonly, strong) UICollectionView *listView;
@property (nonatomic, readonly, strong) NSMutableArray<CHChannelModel *> *channels;

@end

@implementation CHChannelsViewController

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
    [listView registerClass:CHChannelCell.class forCellWithReuseIdentifier:cellIdentifier];
    listView.backgroundColor = theme.groupedBackgroundColor;
    listView.delegate = self;
    listView.dataSource = self;

    _channels = [NSMutableArray arrayWithArray:[CHLogic.shared.userDataSource loadChannels]];
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
    [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": [self.channels objectAtIndex:indexPath.row].cid }];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.channels.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CHChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell != nil) {
        cell.model = [self.channels objectAtIndex:indexPath.row];
    }
    return cell;
}

#pragma mark - CHLogicDelegate
- (void)logicMessageUpdated:(NSArray<NSNumber *> *)mids {
    CHUserDataSource *usrDS = CHLogic.shared.userDataSource;
    for (NSNumber *m in mids) {
        uint64_t mid = m.unsignedLongLongValue;
        CHMessageModel *model = [usrDS messageWithMID:mid];
        for (CHChannelModel *chan in self.channels) {
            if ([model.channel.base64 isEqualToString:chan.cid]) {
                chan.mid = mid;
                [self.channels removeObject:chan];
                [self.channels insertObject:chan atIndex:0];
                break;
            }
        }
    }
    [self.listView reloadData];
}


@end
