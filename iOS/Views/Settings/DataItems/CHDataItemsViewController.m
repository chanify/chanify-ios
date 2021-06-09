//
//  CHDataItemsViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/26.
//

#import "CHDataItemsViewController.h"
#import <Masonry/Masonry.h>
#import "CHLoadMoreView.h"
#import "CHTableView.h"
#import "CHRouter.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

@interface CHDataItemsViewController () <UITableViewDelegate>

@property (nonatomic, readonly, weak) CHWebCacheManager *manager;
@property (nonatomic, readonly, strong) Class cellClass;
@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHDataListDataSource *dataSource;
@property (nonatomic, readonly, strong) NSDirectoryEnumerator *enumerator;

@end

@implementation CHDataItemsViewController

- (instancetype)initWithCellClass:(Class)clz manager:(CHWebCacheManager *)manager {
    if (self = [super init]) {
        _name = @"";
        _pageSize = 10;
        _cellClass = clz;
        _manager = manager;
        _enumerator = self.manager.fileEnumerator;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:self.cellClass forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView new];
    tableView.rowHeight = [self.cellClass cellHeight];
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;

    @weakify(self);
    _dataSource = [[CHDataListDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, NSURL *url) {
        CHDataItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            @strongify(self);
            [cell setURL:url manager:self.manager];
        }
        return cell;
    }];
    [self loadMore:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.isEditing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self previewURL:[self.dataSource itemIdentifierForIndexPath:indexPath] atView:[tableView cellForRowAtIndexPath:indexPath]];
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

#pragma mark - Subclass Methods
- (void)previewURL:(NSURL *)url atView:(UIView *)view {
}

#pragma mark - Action Methods
- (void)actionDelete:(id)sender {
    NSMutableArray<NSURL *> *items = [NSMutableArray new];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [items addObject:[self.dataSource itemIdentifierForIndexPath:indexPath]];
    }
    if (items.count > 0) {
        @weakify(self);
        NSString *format = [NSString stringWithFormat:@"Delete %%d selected %@s or not?", self.name];
        [CHRouter.shared showAlertWithTitle:[NSString stringWithFormat:format.localized, items.count] action:@"Delete".localized handler:^{
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
        CHDataListDiffableSnapshot *snapshot = self.dataSource.snapshot;
        NSInteger idx = 0;
        NSMutableArray *items = [NSMutableArray new];
        for (NSURL *url in self.enumerator) {
            NSNumber *isDir = nil;
            if ([url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil] && ![isDir boolValue]) {
                [items addObject:url];
                if (++idx >= self.pageSize) {
                    break;
                }
            }
        }
        if (idx >= self.pageSize) {
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
    [self.manager removeWithURLs:items];
    CHDataListDiffableSnapshot *snapshot = self.dataSource.snapshot;
    [snapshot deleteItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
    [self scrollViewDidScroll:self.tableView];
}

- (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    @weakify(self);
    CHDataItemCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSURL *url = [cell url];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        @strongify(self);
        [self previewURL:url atView:cell];
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
        [CHRouter.shared showAlertWithTitle:[NSString stringWithFormat:@"Delete this %@ or not?", self.name].localized action:@"Delete".localized handler:^{
            @strongify(self);
            [self deleteItems:@[url]];
        }];
        completionHandler(YES);
    }];
    action.image = [UIImage systemImageNamed:@"trash.fill"];
    action.backgroundColor = CHTheme.shared.alertColor;
    return action;
}


@end
