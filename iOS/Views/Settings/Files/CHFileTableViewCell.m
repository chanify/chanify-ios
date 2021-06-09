//
//  CHFileTableViewCell.m
//  iOS
//
//  Created by WizJin on 2021/5/25.
//

#import "CHFileTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHFileTableViewCell ()

@property (nonatomic, readonly, strong) UIImageView *iconView;
@property (nonatomic, readonly, strong) UILabel *nameLabel;
@property (nonatomic, readonly, strong) UILabel *createDateLabel;
@property (nonatomic, readonly, strong) UILabel *fileSizeLabel;

@end

@implementation CHFileTableViewCell

+ (CGFloat)cellHeight {
    return 65;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.fill"]];
        [self.contentView addSubview:(_iconView = iconView)];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.tintColor = theme.lightLabelColor;
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(kCHDataItemCellMargin);
            make.centerY.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(26, 32));
        }];
        
        UILabel *fileSizeLabel = [UILabel new];
        [self.contentView addSubview:(_fileSizeLabel = fileSizeLabel)];
        [fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-kCHDataItemCellMargin);
            make.bottom.equalTo(self.contentView).offset(-6);
        }];
        fileSizeLabel.font = [UIFont systemFontOfSize:12];
        fileSizeLabel.textColor = theme.lightLabelColor;
        fileSizeLabel.numberOfLines = 1;
        
        UILabel *createDateLabel = [UILabel new];
        [self.contentView addSubview:(_createDateLabel = createDateLabel)];
        [createDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(10);
            make.bottom.equalTo(self.contentView).offset(-6);
            make.height.equalTo(fileSizeLabel);
        }];
        createDateLabel.font = [UIFont systemFontOfSize:12];
        createDateLabel.textColor = theme.minorLabelColor;
        createDateLabel.numberOfLines = 1;

        UILabel *nameLabel = [UILabel new];
        [self.contentView addSubview:(_nameLabel = nameLabel)];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(6);
            make.right.equalTo(self.contentView).offset(-kCHDataItemCellMargin);
            make.left.equalTo(createDateLabel);
            make.bottom.equalTo(createDateLabel.mas_top).offset(-4);
        }];
        nameLabel.font = [UIFont systemFontOfSize:16];
        nameLabel.textColor = theme.labelColor;
        nameLabel.numberOfLines = 1;
    }
    return self;
}

- (void)setURL:(NSURL *)url manager:(CHWebCacheManager *)manager {
    if (self.url != url) {
        self.url = url;

        NSDictionary *info = [manager infoWithURL:url];
        self.nameLabel.text = [info valueForKey:@"name"];
        self.createDateLabel.text = [[info valueForKey:@"date"] mediumFormat];
        self.fileSizeLabel.text = [[info valueForKey:@"size"] formatFileSize];
    }
}


@end
