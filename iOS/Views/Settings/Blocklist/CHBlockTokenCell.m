//
//  CHBlockTokenCell.m
//  iOS
//
//  Created by WizJin on 2021/6/4.
//

#import "CHBlockTokenCell.h"
#import <Masonry/Masonry.h>
#import "CHCodeFormatter.h"
#import "CHTheme.h"

@interface CHBlockTokenCell ()

@property (nonatomic, readonly, strong) UILabel *tokenLabel;

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
            make.centerY.equalTo(self.contentView);
        }];
        tokenLabel.font = [UIFont fontWithName:@kCHCodeFontName size:15];
        tokenLabel.textColor = theme.labelColor;
        tokenLabel.numberOfLines = 1;
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

- (void)setToken:(NSString *)token {
    self.textLabel.text = [CHCodeFormatter.shared stringForObjectValue:token];
}


@end
