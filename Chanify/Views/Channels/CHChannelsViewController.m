//
//  CHChannelsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelsViewController.h"
#import <Masonry/Masonry.h>
#import "CHChannelTableView.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHRouter.h"
#import "CHLogic.h"

typedef UITableViewDiffableDataSource<NSString *, CHChannelModel *> CHChannelDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHChannelModel *> CHChannelDiffableSnapshot;

static NSString *const cellIdentifier = @"chan";

@interface CHChannelsViewController () <UITableViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHChannelTableView *tableView;
@property (nonatomic, readonly, strong) CHChannelDataSource *dataSource;

@end

@implementation CHChannelsViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

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

    CHChannelTableView *tableView = [CHChannelTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:CHChannelTableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.delegate = self;

    _dataSource = [[CHChannelDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHChannelModel *item) {
        CHChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = item;
        }
        return cell;
    }];
    
    [self reloadChannels];
    
    [CHLogic.shared addDelegate:self];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHChannelModel *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid }];
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray arrayWithObject:[CHChannelTableViewCell actionInfo:tableView indexPath:indexPath]];
    UIContextualAction *delete = [CHChannelTableViewCell actionDelete:tableView indexPath:indexPath];
    if (delete != nil) {
        [actions insertObject:delete atIndex:0];
    }
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:actions];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
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
