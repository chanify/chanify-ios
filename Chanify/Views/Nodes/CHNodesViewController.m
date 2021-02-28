//
//  CHNodesViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/23.
//

#import "CHNodesViewController.h"
#import <Masonry/Masonry.h>
#import "CHNodeTableViewCell.h"
#import "CHTableView.h"
#import "CHUserDataSource.h"
#import "CHRouter.h"
#import "CHLogic.h"

typedef UITableViewDiffableDataSource<NSString *, CHNodeModel *> CHNodeDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHNodeModel *> CHNodeDiffableSnapshot;

static NSString *const cellIdentifier = @"node";

@interface CHNodesViewController () <UITableViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHNodeDataSource *dataSource;

@end

@implementation CHNodesViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(actionAddNode:)];
    
    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:CHNodeTableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.rowHeight = 61;
    tableView.delegate = self;

    _dataSource = [[CHNodeDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHNodeModel *item) {
        CHNodeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = item;
        }
        return cell;
    }];
    [CHLogic.shared addDelegate:self];
    [self reloadData];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHNodeModel *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        [CHRouter.shared routeTo:@"/page/node" withParams:@{ @"nid": item.nid }];
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray arrayWithObject:[CHNodeTableViewCell actionInfo:tableView indexPath:indexPath]];
    UIContextualAction *delete = [CHNodeTableViewCell actionDelete:tableView indexPath:indexPath];
    if (delete != nil) {
        [actions insertObject:delete atIndex:0];
    }
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:actions];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
}

#pragma mark - CHLogicDelegate
- (void)logicNodeUpdated:(NSString *)nid {
    [self reloadData];
}

- (void)logicNodesUpdated:(NSArray<NSString *> *)nids {
    [self reloadData];
}

#pragma mark - Action Methods
- (void)actionAddNode:(id)sender {
    [CHRouter.shared routeTo:@"/page/scan"];
}

#pragma mark - Private Methods
- (void)reloadData {
    CHNodeDiffableSnapshot *snapshot = [CHNodeDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[CHLogic.shared.userDataSource loadNodes]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}


@end
