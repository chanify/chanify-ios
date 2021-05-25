//
//  CHFilesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHFilesViewController.h"
#import <Masonry/Masonry.h>
#import "CHPreviewController.h"
#import "CHFileTableViewCell.h"
#import "CHLoadMoreView.h"
#import "CHTableView.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"
#import "CHTheme.h"

#define kCHFileTableMaxN   20

typedef UITableViewDiffableDataSource<NSString *, NSURL *> CHFilesDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSURL *> CHFilesDiffableSnapshot;

static NSString *const cellIdentifier = @"file";

@interface CHFilesViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHFilesDataSource *dataSource;
@property (nonatomic, readonly, strong) NSDirectoryEnumerator *enumerator;

@end

@implementation CHFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Files".localized;

    _enumerator = CHLogic.shared.webFileManager.fileEnumerator;
    
    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:CHFileTableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView new];
    tableView.rowHeight = 41;
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;

    _dataSource = [[CHFilesDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, NSURL *url) {
        CHFileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.url = url;
        }
        return cell;
    }];
    [self loadMore:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.isEditing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        previewURL([self.dataSource itemIdentifierForIndexPath:indexPath]);
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[
        [self actionDelete:tableView indexPath:indexPath],
        [self actionInfo:tableView indexPath:indexPath],
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.enumerator != nil) {
        CGFloat y = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.size.height;
        if (y <= 0) {
            CHLoadMoreView *loadMore = (CHLoadMoreView *)self.tableView.tableFooterView;
            if (loadMore.status != CHLoadStatusLoading) {
                loadMore.status = CHLoadStatusLoading;
                @weakify(self);
                dispatch_main_after(kCHLoadingDuration, ^{
                    @strongify(self);
                    [self loadMore:YES];
                });
            }
        }
    }
}

#pragma mark - Action Methods
- (void)actionDelete:(id)sender {
    NSMutableArray<NSURL *> *items = [NSMutableArray new];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [items addObject:[self.dataSource itemIdentifierForIndexPath:indexPath]];
    }
    if (items.count > 0) {
        @weakify(self);
        [CHRouter.shared showAlertWithTitle:[NSString stringWithFormat:@"Delete %d selected files or not?".localized, items.count] action:@"Delete".localized handler:^{
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

#pragma mark - Private Nethods
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing];
    if (editing) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionCancel:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete".localized style:UIBarButtonItemStylePlain target:self action:@selector(actionDelete:)];
        self.navigationItem.leftBarButtonItem.tintColor = CHTheme.shared.alertColor;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
    }
    [super setEditing:editing animated:animated];
}

- (void)loadMore:(BOOL)animated {
    if (self.enumerator != nil) {
        CHLoadMoreView *loadMore = (CHLoadMoreView *)self.tableView.tableFooterView;
        CHFilesDiffableSnapshot *snapshot = self.dataSource.snapshot;
        NSInteger idx = 0;
        NSMutableArray *items = [NSMutableArray new];
        for (NSURL *url in self.enumerator) {
            [items addObject:url];
            if (++idx >= kCHFileTableMaxN) {
                break;
            }
        }
        if (idx >= kCHFileTableMaxN) {
            loadMore.status = CHLoadStatusNormal;
        } else {
            _enumerator = nil;
            loadMore.status = CHLoadStatusFinish;
        }
        if (snapshot.numberOfSections <= 0) {
            [snapshot appendSectionsWithIdentifiers:@[@""]];
        }
        [snapshot appendItemsWithIdentifiers:items];
        [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
    }
}

- (void)deleteItems:(NSArray<NSURL *> *)items {
    [CHLogic.shared.webFileManager removeWithURLs:items];
    CHFilesDiffableSnapshot *snapshot = self.dataSource.snapshot;
    [snapshot deleteItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
    [self scrollViewDidScroll:self.tableView];
}

- (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    NSURL *url = [[tableView cellForRowAtIndexPath:indexPath] url];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        previewURL(url);
        completionHandler(YES);
    }];
    action.image = [UIImage systemImageNamed:@"info.circle.fill"];
    action.backgroundColor = CHTheme.shared.secureColor;
    return action;
}

- (UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    @weakify(self);
    NSURL *url = [[tableView cellForRowAtIndexPath:indexPath] url];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [CHRouter.shared showAlertWithTitle:@"Delete this file or not?".localized action:@"Delete".localized handler:^{
            @strongify(self);
            [self deleteItems:@[url]];
        }];
        completionHandler(YES);
    }];
    action.image = [UIImage systemImageNamed:@"trash.fill"];
    action.backgroundColor = CHTheme.shared.alertColor;
    return action;
}

static inline void previewURL(NSURL *url) {
    CHPreviewController *vc = [CHPreviewController previewFile:url];
    [CHRouter.shared presentSystemViewController:vc animated:YES];
}


@end
