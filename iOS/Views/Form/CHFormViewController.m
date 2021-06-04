//
//  CHFormViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormViewController.h"
#import <Masonry/Masonry.h>
#import "CHFormSectionHeaderView.h"

static NSString *const cellIdentifier = @"cell";
static NSString *const headerIdentifier = @"header";

typedef UITableViewDiffableDataSource<CHFormSection *, CHFormItem *> CHFormDataSource;
typedef NSDiffableDataSourceSnapshot<CHFormSection *, CHFormItem *> CHFormDiffableSnapshot;

@interface CHFormViewController () <UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, readonly, strong) UITableView *tableView;
@property (nonatomic, nullable, strong) UIToolbar *inputAccessoryView;
@property (nonatomic, readonly, strong) CHFormDataSource *dataSource;
@property (nonatomic, nullable, weak) CHFormInputItem *currentInput;

@end

@implementation CHFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentInput = nil;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:CHFormSectionHeaderView.class forHeaderFooterViewReuseIdentifier:headerIdentifier];
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.delegate = self;
    
    _dataSource = [[CHFormDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHFormItem *item) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            [item prepareCell:cell];
        }
        return cell;
    }];
    
    [self updateForm:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.form != nil && self.form.assignFirstResponderOnShow) {
        self.form.assignFirstResponderOnShow = NO;
        NSArray<CHFormInputItem *> *items = self.form.inputItems;
        if (items.count > 0) {
            [items.firstObject startEditing];
        }
    }
}

- (void)setForm:(CHForm *)form {
    if (self.form != nil) {
        if (self.dataSource != nil) {
            CHFormDiffableSnapshot *snapshot = self.dataSource.snapshot;
            [snapshot deleteAllItems];
            [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
        }
    }
    _form = form;
    [self updateForm:NO];
}

- (void)reloadData {
    if (self.form != nil && self.dataSource != nil) {
        [self.form reloadData];
        CHFormDiffableSnapshot *snapshot = self.dataSource.snapshot;
        [snapshot deleteAllItems];
        [snapshot appendSectionsWithIdentifiers:self.form.sections];
        for (CHFormSection *section in self.form.sections) {
            [snapshot appendItemsWithIdentifiers:section.items intoSectionWithIdentifier:section];
        }
        [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated];
    }
}

- (void)reloadItem:(CHFormItem *)item {
    if (self.dataSource != nil && item != nil) {
        CHFormDiffableSnapshot *snapshot = self.dataSource.snapshot;
        if ([snapshot indexOfItemIdentifier:item] != NSNotFound) {
            [snapshot reloadItemsWithIdentifiers:@[item]];
        }
        [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated];
    }
}

- (void)reloadSection:(CHFormSection *)section {
    if (self.dataSource != nil && section != nil) {
        CHFormDiffableSnapshot *snapshot = self.dataSource.snapshot;
        if ([snapshot indexOfSectionIdentifier:section] != NSNotFound) {
            [snapshot reloadSectionsWithIdentifiers:@[section]];
        }
        [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated];
    }
}

- (void)showActionSheet:(UIAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated {
    UITableViewCell *cell = [self cellForItem:item];
    if (cell != nil) {
        CGRect frame = cell.contentView.frame;
        if ([cell.contentView isKindOfClass:UIListContentView.class]) {
            UIListContentView *contentView = (UIListContentView *)cell.contentView;
            if (contentView.configuration.secondaryText.length > 0) {
                frame = contentView.secondaryTextLayoutGuide.layoutFrame;
            } else {
                frame = contentView.textLayoutGuide.layoutFrame;
            }
        }
        alertController.popoverPresentationController.sourceView = self.tableView;
        alertController.popoverPresentationController.sourceRect = [self.tableView convertRect:frame fromView:cell];
    }
    [self.tableView endEditing:YES];
    [self presentViewController:alertController animated:animated completion:nil];
}

- (nullable UITableViewCell *)cellForItem:(CHFormItem *)item {
    return [self.tableView cellForRowAtIndexPath:[self.dataSource indexPathForItemIdentifier:item]];
}

- (BOOL)itemIsLastInput:(CHFormInputItem *)item {
    if (item != nil) {
        NSArray<CHFormInputItem *> *items = self.form.inputItems;
        return (items.count > 0 && items.lastObject == item);
    }
    return NO;
}

- (BOOL)itemShouldInputReturn:(CHFormInputItem *)item {
    [self actionGotoInputNext:nil];
    return YES;
}

- (UIToolbar *)itemAccessoryView:(CHFormInputItem *)item {
    NSArray<CHFormInputItem *> *items = self.form.inputItems;
    UIToolbar *toolBar = self.inputAccessoryView;
    [[toolBar.items objectAtIndex:0] setEnabled: (items.count > 0 ? items.firstObject != item : NO)];
    [[toolBar.items objectAtIndex:2] setEnabled: (items.count > 0 ? items.lastObject != item : NO)];
    return toolBar;
}

- (void)itemBecomeFirstResponder:(CHFormInputItem *)item {
    self.currentInput = item;
    [item.editView becomeFirstResponder];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHFormItem *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    [item tryDoAction];
    if (![item isKindOfClass:CHFormInputItem.class]) {
        [tableView endEditing:YES];
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CHFormSectionHeaderView *headerView = nil;
    NSArray<CHFormSection *> *sections = [self.dataSource.snapshot sectionIdentifiers];
    if (section < sections.count) {
        CHFormSection *item = [sections objectAtIndex:section];;
        NSString *title = item.title;
        if (title.length > 0) {
            headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
            if (headerView != nil) {
                headerView.textLabel.text = title;
                if (item.note.length > 0) {
                    headerView.noteText = item.note;
                }
            }
        }
    }
    return headerView;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.tableView endEditing:YES];
}

#pragma mark - Action Methods
- (void)actionGotoInputPrev:(id)sender {
    NSArray<CHFormInputItem *> *items = self.form.inputItems;
    NSInteger index = [items indexOfObject:self.currentInput] - 1;
    if (index >= 0 && index < items.count) {
        [[items objectAtIndex:index] startEditing];
    }
}

- (void)actionGotoInputNext:(id)sender {
    if ([self itemIsLastInput:self.currentInput]) {
        [self actionGotoInputDone:nil];
    } else {
        NSArray<CHFormInputItem *> *items = self.form.inputItems;
        NSInteger index = [items indexOfObject:self.currentInput] + 1;
        if (index >= 0 && index < items.count) {
            [[items objectAtIndex:index] startEditing];
        }
    }
}

- (void)actionGotoInputDone:(id)sender {
    [self.tableView endEditing:YES];
}

#pragma mark - Private Methods
- (void)updateForm:(BOOL)animated {
    if (self.form != nil) {
        [self.form reloadData];
        self.title = self.form.title;
        if (self.dataSource != nil) {
            CHFormDiffableSnapshot *snapshot = [CHFormDiffableSnapshot new];
            [snapshot appendSectionsWithIdentifiers:self.form.sections];
            for (CHFormSection *section in self.form.sections) {
                [snapshot appendItemsWithIdentifiers:section.items intoSectionWithIdentifier:section];
            }
            [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated && animated];
        }
        self.form.viewController = self;
    }
}

- (BOOL)canAnimated {
    return !CGRectIsEmpty(self.tableView.bounds);
}

- (UIToolbar *)inputAccessoryView {
    if (_inputAccessoryView == nil) {
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        (_inputAccessoryView = toolBar);
        toolBar.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth);
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 22.0;
        [toolBar setItems:@[
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:105 target:self action:@selector(actionGotoInputPrev:)],
            fixedSpace,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:106 target:self action:@selector(actionGotoInputNext:)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionGotoInputDone:)],
        ]];
    }
    return _inputAccessoryView;
}


@end
