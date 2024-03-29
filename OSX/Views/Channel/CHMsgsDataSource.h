//
//  CHMsgsDataSource.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@class CHMessageModel;
@class CHCellConfiguration;

@interface CHMsgsDataSource : NSCollectionViewDiffableDataSource<NSString *, CHCellConfiguration *>

@property (nonatomic, nullable, weak) NSScrollView *scroller;

+ (instancetype)dataSourceWithCollectionView:(NSCollectionView *)collectionView channelID:(NSString *)cid;
- (void)reset:(BOOL)animated;
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)sizeForHeaderInSection:(NSInteger)section;
- (void)clearActivedCellItem;
- (void)scrollViewDidScroll;
- (void)loadLatestMessage:(BOOL)animated;
- (void)deleteMessage:(nullable CHMessageModel *)model animated:(BOOL)animated;
- (void)deleteMessages:(NSArray<NSString *> *)mids animated:(BOOL)animated;
- (void)selectItemWithIndexPaths:(NSSet<NSIndexPath *> *)indexPaths;


@end

NS_ASSUME_NONNULL_END
