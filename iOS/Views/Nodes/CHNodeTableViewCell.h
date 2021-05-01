//
//  CHNodeTableViewCell.h
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHTableViewCell.h"
#import "CHNodeModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHNodeTableViewCell : CHTableViewCell

@property (nonatomic, nullable, strong) CHNodeModel *model;

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
+ (nullable UIContextualAction *)actionReconnect:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;


@end

NS_ASSUME_NONNULL_END
