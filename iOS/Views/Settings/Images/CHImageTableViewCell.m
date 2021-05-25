//
//  CHImageTableViewCell.m
//  iOS
//
//  Created by WizJin on 2021/5/25.
//

#import "CHImageTableViewCell.h"
#import <Masonry/Masonry.h>
#import "CHLogic+iOS.h"
#import "CHTheme.h"

@interface CHImageTableViewCell ()

@property (nonatomic, readonly, strong) UIImageView *imagePreviewView;
@property (nonatomic, readonly, strong) UILabel *createDateLabel;
@property (nonatomic, readonly, strong) UILabel *fileSizeLabel;

@end

@implementation CHImageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CHTheme *theme = CHTheme.shared;

        UIImageView *imagePreviewView = [UIImageView new];
        [self.contentView addSubview:(_imagePreviewView = imagePreviewView)];
        imagePreviewView.contentMode = UIViewContentModeScaleAspectFill;
        imagePreviewView.clipsToBounds = YES;
        [imagePreviewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.top.equalTo(self.contentView).offset(4);
            make.bottom.equalTo(self.contentView).offset(-4);
            make.width.equalTo(imagePreviewView.mas_height);
        }];

        UILabel *createDateLabel = [UILabel new];
        [self.contentView addSubview:(_createDateLabel = createDateLabel)];
        [createDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(6);
        }];
        createDateLabel.font = [UIFont systemFontOfSize:14];
        createDateLabel.textColor = theme.minorLabelColor;
        createDateLabel.numberOfLines = 1;

        UILabel *fileSizeLabel = [UILabel new];
        [self.contentView addSubview:(_fileSizeLabel = fileSizeLabel)];
        [fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.createDateLabel);
            make.bottom.equalTo(self.contentView).offset(-6);
        }];
        fileSizeLabel.font = [UIFont systemFontOfSize:12];
        fileSizeLabel.textColor = theme.lightLabelColor;
        fileSizeLabel.numberOfLines = 1;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.imagePreviewView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(self.isEditing ? 64 : 16);
    }];
}

- (void)setUrl:(NSURL *)url {
    if (_url != url) {
        _url = url;
        NSDictionary *info = [CHLogic.shared.webImageManager infoWithURL:url];
        self.imagePreviewView.image = [info valueForKey:@"data"];
        self.createDateLabel.text = [[info valueForKey:@"date"] mediumFormat];
        self.fileSizeLabel.text = [[info valueForKey:@"size"] formatFileSize];
    }
}


@end
