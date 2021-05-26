//
//  CHDataListController.h
//  iOS
//
//  Created by WizJin on 2021/5/26.
//

#import "CHViewController.h"
#import "CHFileCacheManager.h"
#import "CHDataListCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef UITableViewDiffableDataSource<NSString *, NSURL *> CHDataListDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSURL *> CHDataListDiffableSnapshot;

@interface CHDataListController : CHViewController

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger pageSize;

- (instancetype)initWithCellClass:(Class)clz manager:(CHFileCacheManager *)manager;
- (void)previewURL:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
