//
//  CHBlockTokenCell.m
//  iOS
//
//  Created by WizJin on 2021/6/4.
//

#import "CHBlockTokenCell.h"
#import <Masonry/Masonry.h>
#import "CHIconView.h"
#import "CHCodeFormatter.h"
#import "CHChannelModel.h"
#import "CHUserDataSource.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHBlockTokenCell ()

@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) UILabel *tokenLabel;
@property (nonatomic, readonly, strong) UILabel *channelLabel;
@property (nonatomic, readonly, strong) UILabel *expriedDateLabel;

@end

@implementation CHBlockTokenCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;
        
        UILabel *tokenLabel = [UILabel new];
        [self.contentView addSubview:(_tokenLabel = tokenLabel)];
        [tokenLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(10);
        }];
        tokenLabel.font = [UIFont fontWithName:@kCHCodeFontName size:16];
        tokenLabel.textColor = theme.labelColor;
        tokenLabel.numberOfLines = 1;
        
        CHIconView *iconView = [CHIconView new];
        [self.contentView addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(tokenLabel);
            make.top.equalTo(tokenLabel.mas_bottom).offset(6);
            make.bottom.equalTo(self.contentView).offset(-8);
            make.size.mas_equalTo(CGSizeMake(18, 18));
        }];
        
        UILabel *channelLabel = [UILabel new];
        [self.contentView addSubview:(_channelLabel = channelLabel)];
        [channelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(4);
            make.centerY.equalTo(iconView);
        }];
        channelLabel.font = [UIFont systemFontOfSize:12];
        channelLabel.textColor = theme.minorLabelColor;
        channelLabel.numberOfLines = 1;
        
        UILabel *expriedDateLabel = [UILabel new];
        [self.contentView addSubview:(_expriedDateLabel = expriedDateLabel)];
        [expriedDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(channelLabel.mas_right).offset(4);
            make.right.equalTo(tokenLabel);
            make.bottom.equalTo(channelLabel);
        }];
        expriedDateLabel.font = [UIFont systemFontOfSize:10];
        expriedDateLabel.textColor = theme.lightLabelColor;
        expriedDateLabel.numberOfLines = 1;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.contentView.frame;
    frame.origin.x = (self.isEditing ? 40 : 0);
    frame.size.width = self.bounds.size.width - frame.origin.x;
    self.contentView.frame = frame;
}

- (void)setModel:(CHBlockeModel *)model {
    _model = model;
    self.tokenLabel.text = [CHCodeFormatter.shared formatCode:self.model.raw length:32];
    CHChannelModel *chan = [CHLogic.shared.userDataSource channelWithCID:self.model.channel.base64];
    if (chan == nil) {
        self.iconView.alpha = 0;
        self.channelLabel.text = @"";
    } else {
        self.iconView.alpha = 1;
        self.iconView.image = chan.icon;
        self.channelLabel.text = chan.title;
    }
    NSDate *expired = self.model.expired;
    if (expired == nil) {
        self.expriedDateLabel.text = @"";
    } else {
        if ([NSDate.now compare:expired] == NSOrderedDescending) {
            self.expriedDateLabel.textColor = CHTheme.shared.alertColor;
            self.expriedDateLabel.text = @"Expired".localized;
        } else {
            self.expriedDateLabel.textColor = CHTheme.shared.lightLabelColor;
            self.expriedDateLabel.text = [NSString stringWithFormat:@"Expires at %@".localized, expired.fullDayFormat];
        }
    }
}


@end
