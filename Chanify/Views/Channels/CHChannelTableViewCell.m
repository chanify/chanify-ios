//
//  CHChannelTableViewCell.m
//  Chanify
//
//  Created by WizJin on 2021/2/20.
//

#import "CHChannelTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHBadgeView.h"
#import "CHIconView.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHChannelTableViewCell ()

@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) CHBadgeView *badgeView;
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UILabel *dateLabel;

@end

@implementation CHChannelTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        CHIconView *iconView = [CHIconView new];
        [self.contentView addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.top.equalTo(self.contentView).offset(10);
            make.bottom.equalTo(self.contentView).offset(-10);
            make.width.equalTo(iconView.mas_height);
        }];

        UILabel *titleLabel = [UILabel new];
        [self.contentView addSubview:(_titleLabel = titleLabel)];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(16);
            make.top.equalTo(iconView).offset(3);
        }];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = theme.labelColor;
        titleLabel.numberOfLines = 1;
        
        UILabel *detailLabel = [UILabel new];
        [self.contentView addSubview:(_detailLabel = detailLabel)];
        [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-16);
            make.bottom.equalTo(iconView).offset(-3);
            make.left.equalTo(titleLabel);
        }];
        detailLabel.font = [UIFont systemFontOfSize:16];
        detailLabel.textColor = theme.minorLabelColor;
        detailLabel.numberOfLines = 1;
        
        UILabel *dateLabel = [UILabel new];
        [self.contentView addSubview:(_dateLabel = dateLabel)];
        [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel);
            make.right.equalTo(detailLabel);
            make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(8);
        }];
        dateLabel.font = [UIFont systemFontOfSize:12];
        dateLabel.textColor = theme.lightLabelColor;
        dateLabel.numberOfLines = 1;

        CHBadgeView *badgeView = [CHBadgeView new];
        [self.contentView addSubview:(_badgeView = badgeView)];
        [badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.iconView).offset(-7);
            make.right.equalTo(self.iconView).offset(8);
            make.size.mas_offset(CGSizeMake(18, 18));
        }];

    }
    return self;
}

- (void)setModel:(CHChannelModel *)model {
    _model = model;
    
    CHLogic *logic = CHLogic.shared;

    self.titleLabel.text = model.title;
    self.iconView.image = model.icon;

    NSString *mid = model.mid;
    CHMessageModel *m = [logic.userDataSource messageWithMID:mid];
    self.detailLabel.text = m.summaryText;
    self.dateLabel.text = [NSDate dateFromMID:m.mid].shortFormat;
    
    // TODO: Fix sync when receive push message.
    self.badgeView.count = [logic unreadWithChannel:model.cid];
}

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    CHChannelModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [CHRouter.shared routeTo:@"/page/channel/detail" withParams:@{ @"cid": model.cid, @"show": @"detail" }];
        completionHandler(YES);
    }];
    action.image = [UIImage systemImageNamed:@"info.circle.fill"];
    action.backgroundColor = CHTheme.shared.secureColor;
    return action;
}

+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UIContextualAction *action = nil;
    CHChannelModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    if (model != nil && model.type == CHChanTypeUser) {
        action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHRouter.shared showAlertWithTitle:@"Delete this channel or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteChannel:model.cid];
            }];
            completionHandler(YES);
        }];
        action.image = [UIImage systemImageNamed:@"trash.fill"];
    }
    return action;
}


@end
