//
//  CHDataItemsViewController.h
//  iOS
//
//  Created by WizJin on 2021/5/26.
//

#import "CHViewController.h"
#import "CHWebCacheManager.h"
#import "CHDataItemCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef UITableViewDiffableDataSource<NSString *, NSURL *> CHDataListDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSURL *> CHDataListDiffableSnapshot;

@interface CHDataItemsViewController : CHViewController

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger pageSize;

- (instancetype)initWithCellClass:(Class)clz manager:(CHWebCacheManager *)manager;
- (void)previewURL:(NSURL *)url atView:(UIView *)view;


@end

NS_ASSUME_NONNULL_END
