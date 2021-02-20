//
//  CHChannelTableViewCell.h
//  Chanify
//
//  Created by WizJin on 2021/2/20.
//

#import <UIKit/UIKit.h>
#import "CHChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHChannelTableViewCell : UITableViewCell

@property (nonatomic, nullable, strong) CHChannelModel *model;

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;


@end

NS_ASSUME_NONNULL_END
