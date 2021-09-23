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

typedef NSCollectionViewDiffableDataSource<CHFormSection *, CHFormItem *> CHFormDataSource;
typedef NSDiffableDataSourceSnapshot<CHFormSection *, CHFormItem *> CHFormDiffableSnapshot;

static NSString *const cellIdentifier = @"cell";
static NSString *const headerIdentifier = @"header";

@interface CHFormView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>

@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHFormDataSource *dataSource;

@end

@implementation CHFormView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {        
        CHTheme *theme = CHTheme.shared;

        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 1;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        [listView registerClass:CHFormHeaderView.class forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:headerIdentifier];
        listView.backgroundColor = theme.groupedBackgroundColor;
        listView.allowsMultipleSelection = NO;
        listView.selectable = NO;
        listView.delegate = self;

        CHScrollView *scrollView = [CHScrollView new];
        [self addSubview:(_scrollView = scrollView)];
        scrollView.backgroundColor = theme.groupedBackgroundColor;
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
                [item prepareCell:cell];
            }
            return cell;
            return nil;
        }];
        @weakify(self);
        _dataSource.supplementaryViewProvider = ^NSView * _Nullable(NSCollectionView *collectionView, NSString *kind, NSIndexPath *indexPath) {
            if ([kind isEqualToString:NSCollectionElementKindSectionHeader]) {
                CHFormHeaderView *headerView = [collectionView makeSupplementaryViewOfKind:kind withIdentifier:headerIdentifier forIndexPath:indexPath];
                if (headerView != nil) {
                    @strongify(self);
                    headerView.title = [[self.dataSource.snapshot.sectionIdentifiers objectAtIndex:indexPath.section] title];
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


- (NSString *)title {
    return self.form.title ?: @"";
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

- (void)itemBecomeFirstResponder:(CHFormInputItem *)item {
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
    return YES;
}

- (BOOL)itemIsLastInput:(CHFormInputItem *)item {
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
}

- (BOOL)canAnimated {
    return !CGRectIsEmpty(self.listView.bounds);
}


@end
