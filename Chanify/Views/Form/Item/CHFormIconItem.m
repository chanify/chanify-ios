//
//  CHFormIconItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHFormIconItem.h"
#import "CHFormViewController.h"
#import "CHIconView.h"
#import "CHRouter.h"

@implementation CHFormIconItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:value?:@""]) {
        _required = NO;
        self.configuration.secondaryTextProperties.color = UIColor.clearColor;
        self.action = ^(CHFormIconItem *item) {
            [item doSelectIcon];
        };
    }
    return self;
}

- (void)setValue:(id)value {
    [super setValue:value];
    CHIconView *iconView = [self iconViewForCell:[self.section.form.viewController cellForItem:self]];
    if (iconView != nil) {
        iconView.image = self.value;
    }
}

- (void)prepareCell:(UITableViewCell *)cell {
    [super prepareCell:cell];
    CHIconView *iconView = [self iconViewForCell:cell];
    if (iconView != nil) {
        iconView.image = self.value;
    }
}

#pragma mark - Private Methods
- (void)doSelectIcon {
    [CHRouter.shared routeTo:@"/page/icons" withParams:@{ @"icon": self.value }];
}

- (nullable CHIconView *)iconViewForCell:(nullable UITableViewCell *)cell {
    CHIconView *iconView = nil;
    if (cell != nil) {
        UIListContentView *contentView = (UIListContentView *)cell.contentView;
        iconView = [contentView viewWithTag:kCHFormImageViewTag];
        if (iconView == nil) {
            iconView = [CHIconView new];
            [contentView addSubview:iconView];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            [contentView addConstraints:@[
                [iconView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:8],
                [iconView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-8],
                [iconView.rightAnchor constraintEqualToAnchor:contentView.secondaryTextLayoutGuide.rightAnchor],
                [iconView.widthAnchor constraintEqualToAnchor:iconView.heightAnchor],
            ]];
            iconView.tag = kCHFormImageViewTag;
        }
    }
    return iconView;
}


@end
