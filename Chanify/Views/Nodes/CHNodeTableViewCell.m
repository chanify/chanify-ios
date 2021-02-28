//
//  CHNodeTableViewCell.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHAvatarView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHNodeTableViewCell ()

@property (nonatomic, readonly, strong) CHAvatarView *iconView;
@property (nonatomic, readonly, strong) UILabel *nameLabel;

@end

@implementation CHNodeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        CHAvatarView *iconView = [CHAvatarView new];
        [self.contentView addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.top.equalTo(self.contentView).offset(8);
            make.bottom.equalTo(self.contentView).offset(-8);
            make.width.equalTo(iconView.mas_height);
        }];
        
        UILabel *nameLabel = [UILabel new];
        [self.contentView addSubview:(_nameLabel = nameLabel)];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(10);
            make.centerY.equalTo(iconView);
            make.right.lessThanOrEqualTo(self.contentView).offset(-16);
        }];
        nameLabel.font = [UIFont systemFontOfSize:16];
        nameLabel.textColor = theme.labelColor;
        nameLabel.numberOfLines = 1;
    }
    return self;
}

- (void)setModel:(CHNodeModel *)model {
    _model = model;

    self.nameLabel.text = model.name;
    self.iconView.image = model.icon;
}

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    CHNodeModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [CHRouter.shared routeTo:@"/page/node" withParams:@{ @"nid": model.nid }];
        completionHandler(YES);
    }];
    action.image = [UIImage systemImageNamed:@"info.circle.fill"];
    action.backgroundColor = CHTheme.shared.secureColor;
    return action;
}

+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UIContextualAction *action = nil;
    CHNodeModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    if (model != nil && model.nid.length > 0) {
        action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHRouter.shared showAlertWithTitle:@"Delete this node or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteNode:model.nid];
            }];
            completionHandler(YES);
        }];
        action.image = [UIImage systemImageNamed:@"trash.fill"];
    }
    return action;
}


@end
