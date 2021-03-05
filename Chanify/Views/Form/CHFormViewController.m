//
//  CHFormViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormViewController.h"
#import <Masonry/Masonry.h>

static NSString *const cellIdentifier = @"cell";
static NSString *const headIdentifier = @"head";

typedef UITableViewDiffableDataSource<CHFormSection *, CHFormItem *> CHFormDataSource;
typedef NSDiffableDataSourceSnapshot<CHFormSection *, CHFormItem *> CHFormDiffableSnapshot;

@interface CHFormViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) UITableView *tableView;
@property (nonatomic, readonly, strong) CHFormDataSource *dataSource;

@end

@implementation CHFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:headIdentifier];
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.delegate = self;
    
    _dataSource = [[CHFormDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHFormItem *item) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.accessoryType = item.accessoryType;
            cell.contentConfiguration = item.contentConfiguration;
        }
        return cell;
    }];
    
    [self updateForm];
}

- (void)setForm:(CHForm *)form {
    _form = form;
    [self updateForm];
}

- (void)reloadItem:(CHFormItem *)item {
    if (self.dataSource != nil) {
        CHFormDiffableSnapshot *snapshot = self.dataSource.snapshot;
        [snapshot reloadItemsWithIdentifiers:@[item]];
        [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated];
    }
}

- (void)showActionSheet:(UIAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.dataSource indexPathForItemIdentifier:item]];
    if (cell != nil) {
        CGRect frame = cell.contentView.frame;
        frame.origin.x += frame.size.width * 0.9;
        frame.size.width *= 0.1;
        alertController.popoverPresentationController.sourceView = self.tableView;
        alertController.popoverPresentationController.sourceRect = [self.tableView convertRect:frame fromView:cell];
    }
    [self.tableView endEditing:YES];
    [self presentViewController:alertController animated:animated completion:nil];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHFormItem *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (item.action != nil) {
        item.action(item);
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = nil;
    NSArray<CHFormSection *> *sections = [self.dataSource.snapshot sectionIdentifiers];
    if (section < sections.count) {
        NSString *title = [sections objectAtIndex:section].title;
        if (title.length > 0) {
            headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headIdentifier];
            if (headerView != nil) {
                headerView.textLabel.text = title;
            }
        }
    }
    return headerView;
}

#pragma mark - Private Methods
- (void)updateForm {
    if (self.form != nil) {
        self.title = self.form.title;
        if (self.dataSource != nil) {
            CHFormDiffableSnapshot *snapshot = [CHFormDiffableSnapshot new];
            [snapshot appendSectionsWithIdentifiers:self.form.sections];
            for (CHFormSection *section in self.form.sections) {
                [snapshot appendItemsWithIdentifiers:section.items intoSectionWithIdentifier:section];
            }
            [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated];
        }
        self.form.viewController = self;
        
    }
}

- (BOOL)canAnimated {
    return !CGRectIsEmpty(self.tableView.bounds);
}


@end
