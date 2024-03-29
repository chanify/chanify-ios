//
//  CHFormIconItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHFormIconItem.h"
#import "CHIconsViewController.h"
#import "CHIconView.h"
#import "CHForm.h"
#import "CHRouter.h"

@interface CHFormIconItem () <CHIconsViewControllerDelegate>

@end

@implementation CHFormIconItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:value?:@""]) {
        _required = NO;
        self.action = ^(CHFormIconItem *item) {
            [item doSelectIcon];
        };
    }
    return self;
}

- (void)setValue:(id)value {
    [super setValue:value];
    CHIconView *iconView = [self iconViewForCell:[self.section.form.viewDelegate cellForItem:self]];
    if (iconView != nil) {
        iconView.image = self.value;
    }
}

- (__kindof NSString *)textValue {
    return @"";
}

- (void)prepareCell:(CHFormViewCell *)cell {
    [super prepareCell:cell];
    CHIconView *iconView = [self iconViewForCell:cell];
    if (iconView != nil) {
        iconView.image = self.value;
    }
}

#pragma mark - CHIconsViewControllerDelegate
- (void)iconChanged:(NSString *)icon {
    if (![self.value isEqualToString:icon]) {
        id old = self.value;
        self.value = icon;
        [self.section.form notifyItemValueHasChanged:self oldValue:old newValue:icon];
    }
}

#pragma mark - Private Methods
- (void)doSelectIcon {
    CHIconsViewController *vc = [[CHIconsViewController alloc] initWithIcon:self.value];
    vc.delegate = self;
    [CHRouter.shared pushViewController:vc animated:YES];
}

- (nullable CHIconView *)iconViewForCell:(nullable CHFormViewCell *)cell {
    CHIconView *iconView = nil;
    if (cell != nil) {
        CHListContentView *contentView = (CHListContentView *)cell.contentView;
        iconView = [contentView viewWithTagID:kCHFormImageViewTag];
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
            iconView.tagID = kCHFormImageViewTag;
        }
    }
    return iconView;
}


@end
