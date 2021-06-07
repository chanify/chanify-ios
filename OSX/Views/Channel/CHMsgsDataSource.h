//
//  CHMsgsDataSource.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@class CHCellConfiguration;

@interface CHMsgsDataSource : NSCollectionViewDiffableDataSource<NSString *, CHCellConfiguration *>

+ (instancetype)dataSourceWithCollectionView:(NSCollectionView *)collectionView channelID:(NSString *)cid;
- (void)reset:(BOOL)animated;
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)scrollViewDidScroll;
- (void)selectItemWithIndexPaths:(NSSet<NSIndexPath *> *)indexPaths;


@end

NS_ASSUME_NONNULL_END
