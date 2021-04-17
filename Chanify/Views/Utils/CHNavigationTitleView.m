//
//  CHNavigationTitleView.m
//  Chanify
//
//  Created by WizJin on 2021/4/17.
//

#import "CHNavigationTitleView.h"
#import "CHTheme.h"

@interface CHNavigationTitleView ()

@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, weak) UINavigationBar *navigationBar;

@end

@implementation CHNavigationTitleView

- (instancetype)initWithNavigationController:(UINavigationController *)vc {
    if (self = [super initWithFrame:vc.navigationBar.bounds]) {
        _navigationBar = vc.navigationBar;
        UILabel *titleLabel = [UILabel new];
        [self addSubview:(_titleLabel = titleLabel)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = CHTheme.shared.labelColor;
        titleLabel.font = [UIFont boldSystemFontOfSize:18];
        titleLabel.text = vc.visibleViewController.title;
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return size;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.navigationBar.bounds.size.width;
    CGRect frame = self.frame;
    CGFloat xPos = [self convertPoint:frame.origin toView:self.navigationBar].x;
    CGFloat offset = MAX(xPos, width - frame.size.width - xPos);
    self.titleLabel.frame = CGRectMake(offset - xPos, 0, width - offset * 2, frame.size.height);
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}


@end
