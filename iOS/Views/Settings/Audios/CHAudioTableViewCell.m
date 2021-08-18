//
//  CHAudioTableViewCell.m
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHAudioTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHWebAudioManager.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHAudioTableViewCell ()

@property (nonatomic, readonly, strong) UIImageView *iconView;
@property (nonatomic, readonly, strong) UILabel *durationLabel;
@property (nonatomic, readonly, strong) UILabel *createDateLabel;
@property (nonatomic, readonly, strong) UILabel *fileSizeLabel;

@end

@implementation CHAudioTableViewCell

+ (CGFloat)cellHeight {
    return 60;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"music.note"]];
        [self.contentView addSubview:(_iconView = iconView)];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.tintColor = theme.lightLabelColor;
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(kCHDataItemCellMargin);
            make.centerY.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(26, 32));
        }];
        
        UILabel *durationLabel = [UILabel new];
        [self.contentView addSubview:(_durationLabel = durationLabel)];
        [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(kCHDataItemCellMargin);
            make.bottom.equalTo(self.contentView).offset(-6);
        }];
        durationLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        durationLabel.textColor = theme.labelColor;
        durationLabel.numberOfLines = 1;

        UILabel *createDateLabel = [UILabel new];
        [self.contentView addSubview:(_createDateLabel = createDateLabel)];
        [createDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-kCHDataItemCellMargin);
            make.top.equalTo(self.contentView).offset(6);
        }];
        createDateLabel.font = theme.mediumFont;
        createDateLabel.textColor = theme.minorLabelColor;
        createDateLabel.numberOfLines = 1;

        UILabel *fileSizeLabel = [UILabel new];
        [self.contentView addSubview:(_fileSizeLabel = fileSizeLabel)];
        [fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.createDateLabel);
            make.bottom.equalTo(self.contentView).offset(-6);
        }];
        fileSizeLabel.font = theme.detailFont;
        fileSizeLabel.textColor = theme.lightLabelColor;
        fileSizeLabel.numberOfLines = 1;
    }
    return self;
}

- (void)setURL:(NSURL *)url manager:(CHWebCacheManager *)manager {
    if (self.url != url) {
        self.url = url;

        NSDictionary *info = [manager infoWithURL:url];
        self.createDateLabel.text = [[info valueForKey:@"date"] mediumFormat];
        self.fileSizeLabel.text = [[info valueForKey:@"size"] formatFileSize];
        self.durationLabel.text = [[CHLogic.shared.webAudioManager loadLocalURLDuration:url] formatDuration];
    }
}


@end
