//
//  CHActionScriptsViewController.m
//  iOS
//
//  Created by WizJin on 2022/4/1.
//

#import "CHActionScriptsViewController.h"
#import <Masonry/Masonry.h>
#import "CHScriptTableViewCell.h"
#import "CHLoadMoreView.h"
#import "CHTableView.h"
#import "CHUserDataSource.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

typedef UITableViewDiffableDataSource<NSString *, CHScriptModel *> CHScriptsDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHScriptModel *> CHScriptsDiffableSnapshot;

@interface CHActionScriptsViewController () <UITableViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHScriptsDataSource *dataSource;
@property (nonatomic, readonly, strong) UIBarButtonItem *addButtonItem;

@end

@implementation CHActionScriptsViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Action Scripts".localized;

    _addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(actionAddScript:)];
    self.navigationItem.rightBarButtonItem = self.addButtonItem;
    
    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    [tableView registerClass:CHScriptTableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView loadMoreWithStatus:CHLoadStatusFinish];
    tableView.rowHeight = 60;
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;
 
    _dataSource = [[CHScriptsDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHScriptModel *model) {
        CHScriptTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = model;
        }
        return cell;
    }];
    CHLogic *logic = CHLogic.shared;
    [logic addDelegate:self];
    [self reloadData:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.isEditing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        CHScriptModel *model = [self.dataSource itemIdentifierForIndexPath:indexPath];
        if (model != nil) {
            [CHRouter.shared routeTo:@"/page/script" withParams:@{ @"name": model.name, @"show": @"detail" }];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:3];
    [actions addObject:[CHScriptTableViewCell actionInfo:tableView indexPath:indexPath]];
    UIContextualAction *delete = [CHScriptTableViewCell actionDelete:tableView indexPath:indexPath];
    if (delete != nil) {
        [actions insertObject:delete atIndex:0];
    }
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:actions];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
}

#pragma mark - Action Methods
- (void)actionDelete:(id)sender {
}

- (void)actionCancel:(id)sender {
    [self setEditing:NO animated:YES];
}

- (void)actionAddScript:(id)sender {
    [CHRouter.shared routeTo:@"/page/script/new" withParams:@{ @"show": @"detail" }];
}

#pragma mark -
- (void)logicScriptListUpdated:(NSArray<NSString *> *)snames {
    [self reloadData:YES];
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
    NSArray<CHScriptModel *> *items = [CHLogic.shared.userDataSource loadScripts];
    CHScriptsDiffableSnapshot *snapshot = [CHScriptsDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
}


@end
