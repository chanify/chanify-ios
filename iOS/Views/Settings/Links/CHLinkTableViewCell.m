//
//  CHLinkTableViewCell.m
//  iOS
//
//  Created by WizJin on 2021/9/8.
//

#import "CHLinkTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHLinkTableViewCell ()

@property (nonatomic, readonly, strong) UIImageView *iconView;
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *createDateLabel;
@property (nonatomic, readonly, strong) UILabel *fileSizeLabel;

@end

@implementation CHLinkTableViewCell

+ (CGFloat)cellHeight {
    return 78;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.fill"]];
        [self.contentView addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(kCHDataItemCellMargin);
            make.centerY.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(50, 50));
        }];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.tintColor = theme.lightLabelColor;
        iconView.layer.cornerRadius = 8;
        iconView.clipsToBounds = YES;

        UILabel *fileSizeLabel = [UILabel new];
        [self.contentView addSubview:(_fileSizeLabel = fileSizeLabel)];
        [fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-kCHDataItemCellMargin);
            make.bottom.equalTo(self.contentView).offset(-12);
        }];
        fileSizeLabel.font = theme.detailFont;
        fileSizeLabel.textColor = theme.lightLabelColor;
        fileSizeLabel.numberOfLines = 1;
        
        UILabel *createDateLabel = [UILabel new];
        [self.contentView addSubview:(_createDateLabel = createDateLabel)];
        [createDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(10);
            make.bottom.equalTo(self.contentView).offset(-12);
            make.height.equalTo(fileSizeLabel);
        }];
        createDateLabel.font = theme.detailFont;
        createDateLabel.textColor = theme.minorLabelColor;
        createDateLabel.numberOfLines = 1;
        
        UILabel *titleLabel = [UILabel new];
        [self.contentView addSubview:(_titleLabel = titleLabel)];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(6);
            make.right.equalTo(self.contentView).offset(-kCHDataItemCellMargin);
            make.left.equalTo(createDateLabel);
            make.bottom.equalTo(createDateLabel.mas_top).offset(-6);
        }];
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        titleLabel.backgroundColor = CHColor.clearColor;
        titleLabel.textColor = theme.labelColor;
        titleLabel.numberOfLines = 1;
        titleLabel.font = theme.messageTitleFont;
    }
    return self;
}

- (void)setURL:(NSURL *)url manager:(CHWebCacheManager *)manager {
    if (self.url != url) {
        self.url = url;

        NSDictionary *info = [manager infoWithURL:url];
        self.iconView.image = [info valueForKey:@"icon"];
        self.titleLabel.text = [info valueForKey:@"title"];
        self.createDateLabel.text = [[info valueForKey:@"date"] mediumFormat];
        self.fileSizeLabel.text = [[info valueForKey:@"size"] formatFileSize];
    }
}


@end
