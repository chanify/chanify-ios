//
//  CHBlocklistViewController.m
//  iOS
//
//  Created by WizJin on 2021/6/4.
//

#import "CHBlocklistViewController.h"
#import <Masonry/Masonry.h>
#import "CHBlockTokenCell.h"
#import "CHLoadMoreView.h"
#import "CHTableView.h"
#import "CHPasteboard.h"
#import "CHLogic+iOS.h"
#import "CHRouter+iOS.h"
#import "CHToken.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

typedef UITableViewDiffableDataSource<NSString *, CHBlockeModel *> CHTokensDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHBlockeModel *> CHTokensDiffableSnapshot;

@interface CHBlocklistViewController () <UITableViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHTokensDataSource *dataSource;
@property (nonatomic, readonly, strong) UIBarButtonItem *addButtonItem;

@end

@implementation CHBlocklistViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Token blocklist".localized;
    
    _addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(actionAddToken:)];
    self.navigationItem.rightBarButtonItem = self.addButtonItem;

    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:CHBlockTokenCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView loadMoreWithStatus:CHLoadStatusFinish];
    tableView.rowHeight = 60;
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;

    _dataSource = [[CHTokensDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHBlockeModel *model) {
        CHBlockTokenCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = model;
        }
        return cell;
    }];
    [CHLogic.shared addDelegate:self];
    [self reloadData:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.isEditing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *raw = [[self.dataSource itemIdentifierForIndexPath:indexPath] raw];
        if (raw.length > 0) {
            [CHPasteboard.shared copyWithName:@"Token".localized value:raw];
        }
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[
        [self actionDelete:tableView indexPath:indexPath],
    ]];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
}

#pragma mark - CHLogicDelegate
- (void)logicBlockedTokenChanged {
    [self reloadData:YES];
}

#pragma mark - Action Methods
- (void)actionDelete:(id)sender {
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [items addObject:[[self.dataSource itemIdentifierForIndexPath:indexPath] raw]];
    }
    if (items.count > 0) {
        @weakify(self);
        [CHRouter.shared showAlertWithTitle:[NSString stringWithFormat:@"Delete %d selected tokens or not?".localized, items.count] action:@"Delete".localized handler:^{
            @strongify(self);
            [CHRouter.shared showIndicator:YES];
            [self deleteItems:items];
            [CHRouter.shared showIndicator:NO];
            [self setEditing:NO animated:YES];
        }];
    }
}

- (void)actionCancel:(id)sender {
    [self setEditing:NO animated:YES];
}

- (void)actionAddToken:(id)sender {
    [CHRouter.shared routeTo:@"/page/block_token" withParams:@{ @"show": @"detail" }];
}

#pragma mark - Private Nethods
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing];
    if (editing) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionCancel:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionDelete:)];
        self.navigationItem.leftBarButtonItem.tintColor = CHTheme.shared.alertColor;
    } else {
        self.navigationItem.rightBarButtonItem = self.addButtonItem;
        self.navigationItem.leftBarButtonItem = nil;
    }
    [super setEditing:editing animated:animated];
}

- (void)reloadData:(BOOL)animated {
    CHTokensDiffableSnapshot *snapshot = [CHTokensDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    NSArray<NSString *> *tokens = CHLogic.shared.blockedTokens;
    NSMutableArray<CHBlockeModel *> *items = [NSMutableArray arrayWithCapacity:tokens.count];
    for (NSString *raw in tokens) {
        [items addObject:[CHBlockeModel modelWithRaw:raw]];
    }
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
}

- (void)deleteItems:(NSArray<NSString *> *)items {
    [CHLogic.shared removeBlockedTokens:items];
}

- (UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    @weakify(self);
    NSString *raw = [[self.dataSource itemIdentifierForIndexPath:indexPath] raw];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [CHRouter.shared showAlertWithTitle:@"Delete this token or not?".localized action:@"Delete".localized handler:^{
            @strongify(self);
            [self deleteItems:@[raw]];
        }];
        completionHandler(YES);
    }];
    action.image = [UIImage systemImageNamed:@"trash.fill"];
    action.backgroundColor = CHTheme.shared.alertColor;
    return action;
}


@end
