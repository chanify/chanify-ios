//
//  CHSoundCell.m
//  iOS
//
//  Created by WizJin on 2022/3/12.
//

#import "CHSoundCell.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHSoundCell ()

@property (nonatomic, nullable, strong) UIImageView *checkIcon;
@property (nonatomic, readonly, strong) UILabel *nameLabel;

@end

@implementation CHSoundCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _filePath = nil;
        
        CHTheme *theme = CHTheme.shared;
        
        UIImageView *checkIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"]];
        [self.contentView addSubview:(_checkIcon = checkIcon)];
        checkIcon.tintColor = CHTheme.shared.tintColor;
        checkIcon.alpha = 0;
        [checkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.centerY.equalTo(self.contentView);
            make.size.width.mas_equalTo(20);
        }];

        UILabel *nameLabel = [UILabel new];
        [self.contentView addSubview:(_nameLabel = nameLabel)];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.checkIcon.mas_right).offset(16);
            make.centerY.equalTo(self.contentView);
        }];
        nameLabel.font = theme.textFont;
        nameLabel.textColor = theme.labelColor;
        nameLabel.numberOfLines = 1;
    }
    return self;
}

- (void)setCheck:(BOOL)isCheck {
    self.checkIcon.alpha = isCheck ? 1 : 0;
}

- (void)setFilePath:(NSString *)filePath {
    if (![filePath isEqualToString:_filePath]) {
        _filePath = filePath;
        NSString *name = self.filePath.lastPathComponent.stringByDeletingPathExtension;
        self.nameLabel.text = name.length > 0 ? name : @"Default".localized;
    }
}


@end
