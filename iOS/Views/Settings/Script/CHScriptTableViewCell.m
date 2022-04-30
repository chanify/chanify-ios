//
//  CHScriptTableViewCell.m
//  iOS
//
//  Created by WizJin on 2022/4/1.
//

#import "CHScriptTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHScriptTableViewCell ()

@property (nonatomic, readonly, strong) UILabel *nameLabel;
@property (nonatomic, readonly, strong) UILabel *dateLabel;
@property (nonatomic, readonly, strong) UILabel *typeLabel;

@end

@implementation CHScriptTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;
        
        UILabel *nameLabel = [UILabel new];
        [self.contentView addSubview:(_nameLabel = nameLabel)];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.centerY.equalTo(self.contentView);
        }];
        nameLabel.font = theme.textFont;
        nameLabel.textColor = theme.labelColor;
        nameLabel.numberOfLines = 1;
        
        UILabel *dateLabel = [UILabel new];
        [self.contentView addSubview:(_dateLabel = dateLabel)];
        [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(8);
            make.right.equalTo(self.contentView).offset(-16);
            make.left.greaterThanOrEqualTo(nameLabel.mas_right).offset(8);
        }];
        dateLabel.font = theme.detailFont;
        dateLabel.textColor = theme.lightLabelColor;
        dateLabel.numberOfLines = 1;
        
        UILabel *typeLabel = [UILabel new];
        [self.contentView addSubview:(_typeLabel = typeLabel)];
        [typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.contentView).offset(-10);
            make.right.equalTo(dateLabel);
        }];
        typeLabel.font = theme.detailFont;
        typeLabel.textColor = theme.minorLabelColor;
        typeLabel.numberOfLines = 1;
    }
    return self;
}

- (void)setModel:(CHScriptModel *)model {
    _model = model;
    
    self.nameLabel.text = model.name;
    self.typeLabel.text = model.type.localized;
    self.dateLabel.text = model.lastupdate.shortFormat;
}

+ (UIContextualAction *)actionInfo:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UIContextualAction *action = nil;
    CHScriptModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    if (model != nil) {
        action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHRouter.shared routeTo:@"/page/script" withParams:@{ @"name": model.name, @"show": @"detail" }];
            completionHandler(YES);
        }];
        action.image = [CHImage systemImageNamed:@"info.circle.fill"];
        action.backgroundColor = CHTheme.shared.secureColor;
    }
    return action;
}

+ (nullable UIContextualAction *)actionDelete:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UIContextualAction *action = nil;
    CHScriptModel *model = [[tableView cellForRowAtIndexPath:indexPath] model];
    if (model != nil) {
        action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHRouter.shared showAlertWithTitle:@"Delete this script or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteScript:model.name];
            }];
            completionHandler(YES);
        }];
        action.image = [CHImage systemImageNamed:@"trash.fill"];
    }
    return action;
}


@end
