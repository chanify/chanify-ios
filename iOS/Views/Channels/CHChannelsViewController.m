//
//  CHChannelsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelsViewController.h"
#import <Masonry/Masonry.h>
#import "CHChannelTableViewCell.h"
#import "CHNavigationTitleView.h"
#import "CHTableView.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHRouter.h"
#import "CHLogic.h"

typedef UITableViewDiffableDataSource<NSString *, CHChannelModel *> CHChannelDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHChannelModel *> CHChannelDiffableSnapshot;

static NSString *const cellIdentifier = @"chan";

@interface CHChannelsViewController () <UITableViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHChannelDataSource *dataSource;

@end

@implementation CHChannelsViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.titleView = [[CHNavigationTitleView alloc] initWithNavigationController:self.navigationController];

    NSArray *actions = @[
        [UIAction actionWithTitle:@"Scan QR Code".localized image:[UIImage systemImageNamed:@"qrcode.viewfinder"] identifier:@"scan" handler:^(UIAction *action) {
            [CHRouter.shared routeTo:@"/page/scan" withParams:@{ @"show": @"detail" }];
        }],
        [UIAction actionWithTitle:@"New Channel".localized image:[UIImage systemImageNamed:@"plus"] identifier:@"new" handler:^(UIAction *action) {
            [CHRouter.shared routeTo:@"/page/channel/new" withParams:@{ @"show": @"detail" }];
        }]
    ];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithPrimaryAction:actions[0]];
    barItem.menu = [UIMenu menuWithChildren:actions];
    self.navigationItem.rightBarButtonItem = barItem;

    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:CHChannelTableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.rowHeight = 71;
    tableView.delegate = self;

    _dataSource = [[CHChannelDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHChannelModel *item) {
        CHChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = item;
        }
        return cell;
    }];

    CHLogic *logic = CHLogic.shared;
    [logic addDelegate:self];
    [self updateTitleWithUnread:logic.unreadSumAllChannel];
    [self reloadData];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHChannelModel *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid, @"show": @"detail" }];
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
    [self reloadData];
}

- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids {
    [self reloadData];
}

- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids {
    CHUserDataSource *usrDS = CHLogic.shared.userDataSource;
    CHChannelDiffableSnapshot *snapshot = self.dataSource.snapshot;
    NSArray<CHChannelModel *> *items = [snapshot itemIdentifiersInSectionWithIdentifier:@"main"];
    NSHashTable *reloadItems = [NSHashTable weakObjectsHashTable];
    for (NSString *mid in mids) {
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

- (void)logicMessagesUnreadChanged:(NSNumber *)unread {
    [self updateTitleWithUnread:unread.integerValue];
}

#pragma mark - Private Methods
- (void)reloadData {
    NSArray<CHChannelModel *> *items = [CHLogic.shared.userDataSource loadChannels];
    CHChannelDiffableSnapshot *snapshot = [CHChannelDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(messageCompare:)]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

- (void)updateTitleWithUnread:(NSInteger)unread {
    NSString *badge = nil;
    NSString *title = self.title;
    if (unread > 0) {
        badge = (unread > 99 ? @"⋯" : [NSString stringWithFormat:@"%ld", (long)unread]);
        title = [title stringByAppendingString:(unread > 999 ? @" (999+)" : [NSString stringWithFormat:@" (%ld)", (long)unread])];
    }
    [(CHNavigationTitleView *)self.navigationItem.titleView setTitle:title];
    self.tabBarItem.badgeValue = badge;
}


@end
