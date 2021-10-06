//
//  CHDataItemsViewPage.h
//  OSX
//
//  Created by WizJin on 2021/10/6.
//

#import "CHPageView.h"

NS_ASSUME_NONNULL_BEGIN

@class CHWebCacheManager;

typedef NSCollectionViewDiffableDataSource<NSString *, NSURL *> CHDataListDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSURL *> CHDataListDiffableSnapshot;

@interface CHDataItemsViewPage : CHPageView

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger pageSize;

- (instancetype)initWithCellClass:(Class)clz manager:(CHWebCacheManager *)manager;
- (void)previewURL:(NSURL *)url atView:(CHView *)view;


@end

NS_ASSUME_NONNULL_END
