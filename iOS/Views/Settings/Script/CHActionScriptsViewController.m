//
//  CHActionScriptsViewController.m
//  iOS
//
//  Created by WizJin on 2022/4/1.
//

#import "CHActionScriptsViewController.h"
#import <Masonry/Masonry.h>
#import "CHLoadMoreView.h"
#import "CHScriptCell.h"
#import "CHTableView.h"
#import "CHRouter.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

typedef UITableViewDiffableDataSource<NSString *, CHScriptModel *> CHScriptsDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHScriptModel *> CHScriptsDiffableSnapshot;

@interface CHActionScriptsViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHScriptsDataSource *dataSource;
@property (nonatomic, readonly, strong) UIBarButtonItem *addButtonItem;

@end

@implementation CHActionScriptsViewController

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
    [tableView registerClass:CHScriptCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView loadMoreWithStatus:CHLoadStatusFinish];
    tableView.rowHeight = 60;
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;
 
    _dataSource = [[CHScriptsDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHScriptModel *model) {
        CHScriptCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = model;
        }
        return cell;
    }];
    [self reloadData:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.isEditing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
}

#pragma mark - Action Methods
- (void)actionDelete:(id)sender {
}

- (void)actionCancel:(id)sender {
    [self setEditing:NO animated:YES];
}

- (void)actionAddScript:(id)sender {
    [CHRouter.shared routeTo:@"/page/script" withParams:@{ @"show": @"detail" }];
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
}


@end
