//
//  CHMessagesDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CHMessageModel;
@class CHCellConfiguration;

@interface CHMessagesDataSource : UICollectionViewDiffableDataSource<NSString *, CHCellConfiguration *>

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid;
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)sizeForHeaderInSection:(NSInteger)section;
- (void)setNeedRecalcLayoutItem:(CHCellConfiguration *)cell;
- (void)setNeedRecalcLayout;
- (void)scrollViewDidScroll;
- (void)loadLatestMessage:(BOOL)animated;
- (void)deleteMessage:(nullable CHMessageModel *)model animated:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
