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
#import "CHNodeModel.h"
#import "CHUserDataSource.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHBlockTokenCell ()

@property (nonatomic, readonly, strong) UILabel *tokenLabel;
@property (nonatomic, readonly, strong) CHIconView *channelIconView;
@property (nonatomic, readonly, strong) UILabel *channelTitleLabel;
@property (nonatomic, readonly, strong) CHIconView *nodeIconView;
@property (nonatomic, readonly, strong) UILabel *nodeTitleLabel;
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
        
        CHIconView *channelIconView = [CHIconView new];
        [self.contentView addSubview:(_channelIconView = channelIconView)];
        [channelIconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(tokenLabel);
            make.top.equalTo(tokenLabel.mas_bottom).offset(6);
            make.size.mas_equalTo(CGSizeMake(18, 18));
        }];
        
        UILabel *channelTitleLabel = [UILabel new];
        [self.contentView addSubview:(_channelTitleLabel = channelTitleLabel)];
        [channelTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(channelIconView.mas_right).offset(4);
            make.centerY.equalTo(channelIconView);
        }];
        channelTitleLabel.font = theme.detailFont;
        channelTitleLabel.textColor = theme.minorLabelColor;
        channelTitleLabel.numberOfLines = 1;
        
        CHIconView *nodeIconView = [CHIconView new];
        [self.contentView addSubview:(_nodeIconView = nodeIconView)];
        [nodeIconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(channelIconView);
            make.top.equalTo(channelIconView.mas_bottom).offset(4);
            make.size.equalTo(channelIconView);
            make.bottom.equalTo(self.contentView).offset(-8);
        }];
        
        UILabel *nodeTitleLabel = [UILabel new];
        [self.contentView addSubview:(_nodeTitleLabel = nodeTitleLabel)];
        [nodeTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(channelTitleLabel);
            make.centerY.equalTo(nodeIconView);
        }];
        nodeTitleLabel.font = theme.detailFont;
        nodeTitleLabel.textColor = theme.minorLabelColor;
        nodeTitleLabel.numberOfLines = 1;
        
        UILabel *expriedDateLabel = [UILabel new];
        [self.contentView addSubview:(_expriedDateLabel = expriedDateLabel)];
        [expriedDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(nodeTitleLabel.mas_right).offset(4);
            make.right.equalTo(tokenLabel);
            make.bottom.equalTo(nodeTitleLabel);
        }];
        expriedDateLabel.font = theme.smallFont;
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

- (void)setModel:(CHBlockedModel *)model {
    _model = model;
    self.tokenLabel.text = [CHCodeFormatter.shared formatCode:self.model.raw length:32];
    CHChannelModel *chan = [CHLogic.shared.userDataSource channelWithCID:self.model.channel.base64];
    if (chan == nil) {
        self.channelIconView.alpha = 0;
        self.channelTitleLabel.text = @"";
    } else {
        self.channelIconView.alpha = 1;
        self.channelIconView.image = chan.icon;
        self.channelTitleLabel.text = chan.title;
    }
    CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:self.model.nid];
    if (node == nil) {
        self.nodeIconView.alpha = 0;
        self.nodeTitleLabel.text = @"";
    } else {
        self.nodeIconView.alpha = 1;
        self.nodeIconView.image = node.icon;
        self.nodeTitleLabel.text = node.name;
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
