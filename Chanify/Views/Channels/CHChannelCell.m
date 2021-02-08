//
//  CHChannelCell.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelCell.h"
#import <Masonry/Masonry.h>
#import "CHAvatarView.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHChannelCell ()

@property (nonatomic, readonly, strong) CHAvatarView *iconView;
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UILabel *dateLabel;

@end

@implementation CHChannelCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CHTheme *theme = CHTheme.shared;
        
        self.backgroundConfiguration = UIBackgroundConfiguration.listGroupedCellConfiguration;
        CHAvatarView *iconView = [CHAvatarView new];
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
            make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(4);
        }];
        dateLabel.font = [UIFont systemFontOfSize:12];
        dateLabel.textColor = theme.lightLabelColor;
        dateLabel.numberOfLines = 1;
        
        _model = nil;
    }
    return self;
}

- (void)setModel:(CHChannelModel *)model {
    if (![self.model isEqual:model]) {
        _model = model;
        self.titleLabel.text = model.name;
        self.detailLabel.text = @"";
        self.iconView.image = model.icon;
        uint64_t mid = model.mid;
        CHMessageModel *m = [CHLogic.shared.userDataSource messageWithMID:mid];
        self.detailLabel.text = m.text;
        self.dateLabel.text = m.dateFormat;
    }
}


@end
