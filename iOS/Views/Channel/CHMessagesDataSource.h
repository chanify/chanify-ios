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
@class CHMessagesDataSource;

@protocol CHMessagesDataSourceDelegate <NSObject>
- (void)messagesDataSourceBeginEditing:(CHMessagesDataSource *)dataSource indexPath:(NSIndexPath *)indexPath;
- (BOOL)messagesDataSourceReciveNewMessage;
@end

@interface CHMessagesDataSource : UICollectionViewDiffableDataSource<NSString *, CHCellConfiguration *>

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid;
- (void)reset:(BOOL)animated;
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)sizeForHeaderInSection:(NSInteger)section;
- (void)clearActivedCellItem;
- (void)setNeedRecalcLayout;
- (void)scrollViewDidScroll;
- (void)scrollToBottom:(BOOL)animated;
- (void)loadLatestMessage:(BOOL)animated;
- (void)deleteMessage:(nullable CHMessageModel *)model animated:(BOOL)animated;
- (void)deleteMessages:(NSArray<NSString *> *)mids animated:(BOOL)animated;
- (void)selectItemWithIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSString *> *)selectedItemMIDs;


@end

NS_ASSUME_NONNULL_END
