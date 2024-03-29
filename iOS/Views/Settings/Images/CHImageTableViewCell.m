//
//  CHImageTableViewCell.m
//  iOS
//
//  Created by WizJin on 2021/5/25.
//

#import "CHImageTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHWebImageManager.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHImageTableViewCell ()

@property (nonatomic, readonly, strong) UIImageView *imagePreviewView;
@property (nonatomic, readonly, strong) UILabel *createDateLabel;
@property (nonatomic, readonly, strong) UILabel *fileSizeLabel;

@end

@implementation CHImageTableViewCell

+ (CGFloat)cellHeight {
    return 91;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        UIImageView *imagePreviewView = [UIImageView new];
        [self.contentView addSubview:(_imagePreviewView = imagePreviewView)];
        imagePreviewView.contentMode = UIViewContentModeScaleAspectFill;
        imagePreviewView.clipsToBounds = YES;
        [imagePreviewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(kCHDataItemCellMargin);
            make.top.equalTo(self.contentView).offset(4);
            make.bottom.equalTo(self.contentView).offset(-4);
            make.width.equalTo(imagePreviewView.mas_height);
        }];

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

        NSDictionary *info = [CHLogic.shared.webImageManager infoWithURL:url];
        self.imagePreviewView.image = [info valueForKey:@"data"];
        self.createDateLabel.text = [[info valueForKey:@"date"] mediumFormat];
        self.fileSizeLabel.text = [[info valueForKey:@"size"] formatFileSize];
    }
}


@end
