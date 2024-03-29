//
//  CHFormView.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHFormView.h"
#import <Masonry/Masonry.h>
#import "CHScrollView.h"
#import "CHCollectionView.h"
#import "CHFormViewCell.h"
#import "CHFormHeaderView.h"
#import "CHTheme.h"

#define kCHFormViewBottomMargin     60

typedef NSCollectionViewDiffableDataSource<CHFormSection *, CHFormItem *> CHFormDataSource;
typedef NSDiffableDataSourceSnapshot<CHFormSection *, CHFormItem *> CHFormDiffableSnapshot;

static NSString *const cellIdentifier = @"cell";
static NSString *const headerIdentifier = @"header";

@interface CHFormView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>

@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHFormDataSource *dataSource;
@property (nonatomic, nullable, weak) CHFormInputItem *currentInput;

@end

@implementation CHFormView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _currentInput = nil;

        CHTheme *theme = CHTheme.shared;

        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 1;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        [listView registerClass:CHFormHeaderView.class forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:headerIdentifier];
        listView.backgroundColor = theme.groupedBackgroundColor;
        listView.allowsMultipleSelection = NO;
        listView.selectable = YES;
        listView.delegate = self;

        CHScrollView *scrollView = [CHScrollView new];
        [self addSubview:(_scrollView = scrollView)];
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, kCHFormViewBottomMargin, 0);
        scrollView.scrollerInsets = NSEdgeInsetsMake(0, 0, -kCHFormViewBottomMargin, 0);
        scrollView.automaticallyAdjustsContentInsets = NO;
        scrollView.documentView = listView;
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = NO;

        CHCollectionViewCellRegistration *cellRegistration = [CHCollectionViewCellRegistration registrationWithCellClass:CHFormViewCell.class configurationHandler:^(CHFormViewCell *cell, NSIndexPath *indexPath, id<CHContentConfiguration> _Nonnull item) {
            cell.contentConfiguration = item;
        }];
        _dataSource = [[CHFormDataSource alloc] initWithCollectionView:listView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView *collectionView, NSIndexPath *indexPath, CHFormItem *item) {
            CHFormViewCell *cell = [collectionView makeItemWithIdentifier:cellRegistration.itemIdentifier forIndexPath:indexPath];
            if (cell != nil) {
                cellRegistration.configurationHandler(cell, indexPath, item.contentConfiguration);
                cell.item = item;
            }
            return cell;
        }];
        @weakify(self);
        _dataSource.supplementaryViewProvider = ^NSView * _Nullable(NSCollectionView *collectionView, NSString *kind, NSIndexPath *indexPath) {
            if ([kind isEqualToString:NSCollectionElementKindSectionHeader]) {
                CHFormHeaderView *headerView = [collectionView makeSupplementaryViewOfKind:kind withIdentifier:headerIdentifier forIndexPath:indexPath];
                if (headerView != nil) {
                    @strongify(self);
                    headerView.section = [self.dataSource.snapshot.sectionIdentifiers objectAtIndex:indexPath.section];
                }
                return headerView;
            }
            return nil;
        };
    }
    return self;
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

- (void)layout {
    [super layout];
    self.scrollView.frame = self.bounds;
}

- (void)reloadData {
    [self.listView reloadData];
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

- (void)itemBecomeFirstResponder:(CHFormInputItem *)item {
    self.currentInput = item;
}

- (nullable CHFormViewCell *)cellForItem:(CHFormItem *)item {
    NSCollectionViewItem *cell = [self.listView itemAtIndexPath:[self.dataSource indexPathForItemIdentifier:item]];
    if ([cell isKindOfClass:CHFormViewCell.class]) {
        return (CHFormViewCell *)cell;
    }
    return nil;
}

- (__kindof CHView *)itemAccessoryView:(CHFormInputItem *)item {
    return nil;
}

- (BOOL)itemShouldInputReturn:(CHFormInputItem *)item {
    [self actionGotoInputNext:nil];
    return YES;
}

- (BOOL)itemIsLastInput:(CHFormInputItem *)item {
    if (item != nil) {
        NSArray<CHFormInputItem *> *items = self.form.inputItems;
        return (items.count > 0 && items.lastObject == item);
    }
    return NO;
}

- (void)showActionSheet:(CHAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated {
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [collectionView deselectItemsAtIndexPaths:indexPaths];
    CHFormItem *item = [self.dataSource itemIdentifierForIndexPath:indexPaths.anyObject];
    [item tryDoAction];
    if (![item isKindOfClass:CHFormInputItem.class]) {
        //[collectionView endEditing:YES];
    }
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return NSMakeSize(collectionView.bounds.size.width, 38);
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return NSMakeSize(collectionView.bounds.size.width, 38);
}

#pragma mark - Action Methods
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
    [self.window makeFirstResponder:nil];
}

#pragma mark - Private Methods
- (void)updateForm:(BOOL)animated {
    if (self.form != nil) {
        [self.form reloadData];
        if (self.dataSource != nil) {
            CHFormDiffableSnapshot *snapshot = [CHFormDiffableSnapshot new];
            [snapshot appendSectionsWithIdentifiers:self.form.sections];
            for (CHFormSection *section in self.form.sections) {
                [snapshot appendItemsWithIdentifiers:section.items intoSectionWithIdentifier:section];
            }
            [self.dataSource applySnapshot:snapshot animatingDifferences:self.canAnimated && animated];
        }
        self.form.viewDelegate = self;
    }
    self.title = self.form.title;
}

- (BOOL)canAnimated {
    return !CGRectIsEmpty(self.listView.bounds);
}


@end
