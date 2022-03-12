//
//  CHSoundsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHSoundsViewController.h"
#import <Masonry/Masonry.h>
#import "CHLoadMoreView.h"
#import "CHTableView.h"
#import "CHSoundCell.h"
#import "CHAudioPlayer.h"
#import "CHLogic.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

typedef UITableViewDiffableDataSource<NSString *, NSString *> CHSoundsDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSString *> CHSoundsDiffableSnapshot;

@interface CHSoundsViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHSoundsDataSource *dataSource;

@end

@implementation CHSoundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Sound".localized;
    
    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    [tableView registerClass:CHSoundCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView loadMoreWithStatus:CHLoadStatusFinish];
    tableView.rowHeight = 50;
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;
    
    _dataSource = [[CHSoundsDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, NSString *filePath) {
        CHSoundCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.filePath = filePath;
            cell.check = [filePath isEqualToString:@""];
        }
        return cell;
    }];

    [self reloadData:NO];
}

#pragma mark - Private Methods
- (void)reloadData:(BOOL)animated {
    CHSoundsDiffableSnapshot *snapshot = [CHSoundsDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    NSMutableArray *items = [NSMutableArray arrayWithObject:@""];
    [items addObjectsFromArray:CHLogic.shared.soundManager.soundFiles];
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *filePath = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (filePath.length > 0) {
        [CHAudioPlayer.shared playWithURL:[NSURL fileURLWithPath:filePath] title:filePath.lastPathComponent.stringByDeletingPathExtension];
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


@end
