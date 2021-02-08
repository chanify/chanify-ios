//
//  CHMessagesDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CHCellConfiguration;

@interface CHMessagesDataSource : UICollectionViewDiffableDataSource<NSString *, CHCellConfiguration *>

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid;
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)sizeForHeaderInSection:(NSInteger)section;
- (void)scrollViewDidScroll;
- (void)loadLatestMessage:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
