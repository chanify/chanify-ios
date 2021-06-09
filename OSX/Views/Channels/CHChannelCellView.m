//
//  CHChannelCellView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHChannelCellView.h"
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHBadgeView.h"
#import "CHIconView.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHChannelCellView () <CHLogicDelegate>

@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) CHBadgeView *badgeView;
@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHLabel *detailLabel;
@property (nonatomic, readonly, strong) CHLabel *dateLabel;

@end

@implementation CHChannelCellView

- (void)loadView {
    self.view = [CHView new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CHTheme *theme = CHTheme.shared;
    
    self.view.backgroundColor = theme.cellBackgroundColor;
    
    CHIconView *iconView = [CHIconView new];
    [self.view addSubview:(_iconView = iconView)];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.view).offset(10);
        make.bottom.equalTo(self.view).offset(-10);
        make.width.equalTo(iconView.mas_height);
    }];
    
    CHLabel *titleLabel = [CHLabel new];
    [self.view addSubview:(_titleLabel = titleLabel)];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconView.mas_right).offset(10);
        make.top.equalTo(iconView).offset(1);
    }];
    titleLabel.font = [NSFont systemFontOfSize:14];
    titleLabel.textColor = theme.labelColor;
    titleLabel.maximumNumberOfLines = 1;

    CHLabel *detailLabel = [CHLabel new];
    [self.view addSubview:(_detailLabel = detailLabel)];
    [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-10);
        make.bottom.equalTo(iconView).offset(-1);
        make.left.equalTo(titleLabel);
    }];
    detailLabel.font = [NSFont systemFontOfSize:12];
    detailLabel.textColor = theme.minorLabelColor;
    detailLabel.maximumNumberOfLines = 1;
    
    CHLabel *dateLabel = [CHLabel new];
    [self.view addSubview:(_dateLabel = dateLabel)];
    [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel);
        make.right.equalTo(detailLabel);
        make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(8);
    }];
    dateLabel.font = [NSFont systemFontOfSize:8];
    dateLabel.textColor = theme.lightLabelColor;
    dateLabel.maximumNumberOfLines = 1;
    
    CHBadgeView *badgeView = [[CHBadgeView alloc] initWithFont:[CHFont systemFontOfSize:8]];
    [self.view addSubview:(_badgeView = badgeView)];
    [badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconView).offset(-6);
        make.right.equalTo(self.iconView).offset(7);
        make.size.mas_offset(CGSizeMake(16, 16));
    }];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    CHTheme *theme = CHTheme.shared;
    if (selected) {
        self.view.backgroundColor = theme.selectedCellBackgroundColor;
    } else {
        self.view.backgroundColor = theme.cellBackgroundColor;
    }
}

- (void)setModel:(CHChannelModel *)model {
    _model = model;

    CHLogic *logic = CHLogic.shared;
    
    self.iconView.image = model.icon;
    self.titleLabel.stringValue = model.title;
    
    NSString *mid = model.mid;
    CHMessageModel *m = [logic.userDataSource messageWithMID:mid];
    self.detailLabel.text = m.summaryText;
    self.dateLabel.text = [NSDate dateFromMID:m.mid].shortFormat;
    
    // TODO: Fix sync when receive push message.
    self.badgeView.count = [logic unreadWithChannel:model.cid];
}


@end
