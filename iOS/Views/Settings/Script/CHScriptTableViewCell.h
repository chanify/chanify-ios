//
//  CHScriptTableViewCell.h
//  iOS
//
//  Created by WizJin on 2022/4/1.
//

#import "CHTableViewCell.h"
#import "CHScriptModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHScriptTableViewCell : CHTableViewCell

@property (nonatomic, nullable, strong) CHScriptModel *model;

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;


@end

NS_ASSUME_NONNULL_END
