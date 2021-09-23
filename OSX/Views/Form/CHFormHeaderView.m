//
//  CHFormHeaderView.m
//  OSX
//
//  Created by WizJin on 2021/9/23.
//

#import "CHFormHeaderView.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHFormHeaderView ()

@property (nonatomic, readonly, strong) CHLabel *titleLabel;

@end

@implementation CHFormHeaderView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        CHTheme *theme = CHTheme.shared;

        CHLabel *titleLabel = [CHLabel new];
        [self addSubview:(_titleLabel = titleLabel)];
        titleLabel.textColor = theme.minorLabelColor;
        titleLabel.font = [CHFont systemFontOfSize:11 weight:NSFontWeightRegular];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(CHListContentViewMargin);
            make.bottom.equalTo(self).offset(-4);
        }];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title ?: @"";
}

- (NSString *)title {
    return self.titleLabel.text;
}


@end
