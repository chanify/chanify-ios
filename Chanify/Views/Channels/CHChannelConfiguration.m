//
//  CHChannelConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelConfiguration.h"
#import <Masonry/Masonry.h>
#import "CHAvatarView.h"
#import "CHTheme.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHLogic.h"

@interface CHChannelCellContentView : UIView<UIContentView>

@property (nonatomic, copy) CHChannelConfiguration *configuration;
@property (nonatomic, readonly, strong) CHAvatarView *iconView;
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UILabel *dateLabel;

- (instancetype)initWithConfiguration:(CHChannelConfiguration *)configuration;

@end

@implementation CHChannelCellContentView

- (instancetype)initWithConfiguration:(CHChannelConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _configuration = nil;
        
        CHTheme *theme = CHTheme.shared;
        self.backgroundColor = theme.cellBackgroundColor;
        CHAvatarView *iconView = [CHAvatarView new];
        [self addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(16);
            make.top.equalTo(self).offset(10);
            make.bottom.equalTo(self).offset(-10);
            make.width.equalTo(iconView.mas_height);
        }];

        UILabel *titleLabel = [UILabel new];
        [self addSubview:(_titleLabel = titleLabel)];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(16);
            make.top.equalTo(iconView).offset(3);
        }];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = theme.labelColor;
        titleLabel.numberOfLines = 1;
        
        UILabel *detailLabel = [UILabel new];
        [self addSubview:(_detailLabel = detailLabel)];
        [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-16);
            make.bottom.equalTo(iconView).offset(-3);
            make.left.equalTo(titleLabel);
        }];
        detailLabel.font = [UIFont systemFontOfSize:16];
        detailLabel.textColor = theme.minorLabelColor;
        detailLabel.numberOfLines = 1;
        
        UILabel *dateLabel = [UILabel new];
        [self addSubview:(_dateLabel = dateLabel)];
        [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel);
            make.right.equalTo(detailLabel);
            make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(4);
        }];
        dateLabel.font = [UIFont systemFontOfSize:12];
        dateLabel.textColor = theme.lightLabelColor;
        dateLabel.numberOfLines = 1;
        
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(CHChannelConfiguration *)configuration {
    if (![self.configuration isEqual:configuration]) {
        _configuration = configuration;
        
        self.titleLabel.text = self.configuration.model.name;
        self.detailLabel.text = @"";
        self.iconView.image = self.configuration.model.icon;
        
        uint64_t mid = self.configuration.model.mid;
        CHMessageModel *m = [CHLogic.shared.userDataSource messageWithMID:mid];
        self.detailLabel.text = m.text;
        self.dateLabel.text = [NSDate dateFromMID:m.mid].shortFormat;
    }
}


@end

@implementation CHChannelConfiguration

+ (instancetype)cellConfiguration:(CHChannelModel *)model {
    return [[self.class alloc] initWithModel:model];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithModel:self.model];
}

- (instancetype)initWithModel:(CHChannelModel *)model {
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHChannelCellContentView alloc] initWithConfiguration:self];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}


@end
