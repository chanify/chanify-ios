//
//  CHFormSectionFooterView.m
//  iOS
//
//  Created by WizJin on 2021/6/4.
//

#import "CHFormSectionHeaderView.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHFormSectionHeaderView ()

@property (nonatomic, nullable, strong) UILabel *noteLabel;

@end

@implementation CHFormSectionHeaderView

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_noteLabel != nil) {
        CGRect frame = self.textLabel.frame;
        CGFloat x = frame.origin.x;
        frame.origin.x += frame.size.width + 10;
        frame.size.width = self.bounds.size.width - frame.size.width - x*2 - 8;
        frame.origin.y += 4;
        frame.size.height -= 4;
        _noteLabel.frame = frame;
    }
}

- (void)setNoteText:(nullable NSString *)noteText {
    self.noteLabel.text = noteText ?: @"";
}

- (UILabel *)noteLabel {
    if (_noteLabel == nil) {
        UILabel *label = [UILabel new];
        [self.contentView addSubview:(_noteLabel = label)];
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = CHTheme.shared.lightLabelColor;
        label.font = [UIFont systemFontOfSize:9];
        label.numberOfLines = 1;
    }
    return _noteLabel;
}


@end
