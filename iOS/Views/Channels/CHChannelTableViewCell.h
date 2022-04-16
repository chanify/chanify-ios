//
//  CHChannelTableViewCell.h
//  Chanify
//
//  Created by WizJin on 2021/2/20.
//

#import "CHTableViewCell.h"
#import "CHChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHChannelTableViewCell : CHTableViewCell

@property (nonatomic, nullable, strong) CHChannelModel *model;

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
+ (UIContextualAction *)actionHidden:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;


@end

NS_ASSUME_NONNULL_END
