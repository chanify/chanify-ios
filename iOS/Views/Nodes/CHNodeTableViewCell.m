//
//  CHNodeTableViewCell.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHIconView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHNodeTableViewCell ()

@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) CHLabel *nameLabel;
@property (nonatomic, readonly, strong) CHLabel *endpointLabel;
@property (nonatomic, readonly, strong) CHImageView *statusIcon;

@end

@implementation CHNodeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        CHIconView *iconView = [CHIconView new];
        [self.contentView addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.top.equalTo(self.contentView).offset(8);
            make.bottom.equalTo(self.contentView).offset(-8);
            make.width.equalTo(iconView.mas_height);
        }];
        
        CHImageView *statusIcon = [CHImageView new];
        [self.contentView addSubview:(_statusIcon = statusIcon)];
        [statusIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(30);
            make.centerY.equalTo(self.contentView);
            make.right.equalTo(self.contentView).offset(-16);
        }];
        statusIcon.contentMode = UIViewContentModeScaleAspectFit;
        
        CHLabel *nameLabel = [CHLabel new];
        [self.contentView addSubview:(_nameLabel = nameLabel)];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(10);
            make.top.equalTo(iconView).offset(2);
            make.right.lessThanOrEqualTo(statusIcon.mas_left).offset(-16);
        }];
        nameLabel.font = theme.textFont;
        nameLabel.textColor = theme.labelColor;
        nameLabel.numberOfLines = 1;
        
        CHLabel *endpointLabel = [CHLabel new];
        [self.contentView addSubview:(_endpointLabel = endpointLabel)];
        [endpointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(nameLabel);
            make.right.equalTo(nameLabel);
            make.bottom.equalTo(iconView).offset(-3);
        }];
        endpointLabel.font = theme.detailFont;
        endpointLabel.textColor = theme.minorLabelColor;
        endpointLabel.numberOfLines = 1;
    }
    return self;
}

- (void)setModel:(CHNodeModel *)model {
    _model = model;

    self.nameLabel.text = model.name;
    self.endpointLabel.text = model.endpoint;
    self.iconView.image = model.icon;
    self.statusIcon.hidden = !model.isStoreDevice;
    if ([CHLogic.shared nodeIsConnected:model.nid]) {
        self.statusIcon.image = [CHImage systemImageNamed:@"checkmark.icloud.fill"];
        self.statusIcon.tintColor = CHTheme.shared.secureColor;
    } else {
        self.statusIcon.image = [CHImage systemImageNamed:@"xmark.icloud.fill"];
        self.statusIcon.tintColor = CHTheme.shared.alertColor;
    }
}

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    CHNodeModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [CHRouter.shared routeTo:@"/page/node" withParams:@{ @"nid": model.nid, @"show": @"detail" }];
        completionHandler(YES);
    }];
    action.image = [CHImage systemImageNamed:@"info.circle.fill"];
    action.backgroundColor = CHTheme.shared.secureColor;
    return action;
}

+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UIContextualAction *action = nil;
    CHNodeModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    if (model != nil && !model.isSystem) {
        action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHRouter.shared showAlertWithTitle:@"Delete this node or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteNode:model.nid];
            }];
            completionHandler(YES);
        }];
        action.image = [CHImage systemImageNamed:@"trash.fill"];
    }
    return action;
}

+ (nullable UIContextualAction *)actionReconnect:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UIContextualAction *action = nil;
    CHNodeModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    if (model != nil && model.isStoreDevice) {
        action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHLogic.shared reconnectNode:model.nid completion:^(CHLCode result) {
                if (result == CHLCodeOK) {
                    [CHRouter.shared makeToast:@"Sync device info success".localized];
                } else {
                    [CHRouter.shared makeToast:@"Sync device info failed".localized];
                }
                dispatch_main_after(kCHLoadingDuration, ^{
                    [tableView reloadData];
                });
            }];
            completionHandler(YES);
        }];
        action.image = [CHImage systemImageNamed:@"arrow.clockwise.icloud.fill"];
        action.backgroundColor = CHTheme.shared.warnColor;
    }
    return action;
}


@end
