//
//  CHFormHeaderView.m
//  OSX
//
//  Created by WizJin on 2021/9/23.
//

#import "CHFormHeaderView.h"
#import <Masonry/Masonry.h>
#import "CHForm.h"
#import "CHTheme.h"

@interface CHFormHeaderView ()

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHLabel *noteLabel;

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
        
        CHLabel *noteLabel = [CHLabel new];
        [self addSubview:(_noteLabel = noteLabel)];
        noteLabel.textColor = theme.minorLabelColor;
        noteLabel.alignment = NSTextAlignmentRight;
        noteLabel.font = [CHFont systemFontOfSize:10 weight:NSFontWeightLight];
        [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-CHListContentViewMargin);
            make.left.equalTo(titleLabel.mas_right).offset(4);
            make.bottom.equalTo(titleLabel);
        }];
    }
    return self;
}

- (void)setSection:(CHFormSection * _Nullable)section {
    self.titleLabel.text = section.title ?: @"";
    self.noteLabel.text = section.note ?: @"";
}


@end
