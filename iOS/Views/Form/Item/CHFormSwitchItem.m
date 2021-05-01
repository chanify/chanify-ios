//
//  CHFormSwitchItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/17.
//

#import "CHFormSwitchItem.h"
#import "CHFormViewController.h"
#import "CHTheme.h"

@implementation CHFormSwitchItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:value ?: @""]) {
        _enbaled = NO;
    }
    return self;
}

- (void)prepareCell:(UITableViewCell *)cell {
    [super prepareCell:cell];
    UISwitch *switchView = [self switchViewForCell:cell];
    if (switchView != nil) {
        switchView.on = [self.value boolValue];
        [switchView setHidden:!self.enbaled];
        self.configuration.secondaryText = [self textValue];
        cell.contentConfiguration = self.configuration;
    }
}

- (void)setEnbaled:(BOOL)enbaled {
    if (_enbaled != enbaled) {
        _enbaled = enbaled;
    }
}

- (__kindof NSString *)textValue {
    if (self.enbaled) {
        return @"";
    }
    return [self.value boolValue] ? @"Enable".localized : @"Disable".localized;
}

#pragma mark - Action Methods
- (void)valueChanged:(UISwitch *)sender {
    BOOL old = [self.value boolValue];
    if (old != sender.on) {
        self.value = @(sender.on);
        [self.section.form notifyItemValueHasChanged:self oldValue:@(old) newValue:self.value];
    }
}

#pragma mark - Private Methods
- (nullable UISwitch *)switchViewForCell:(nullable UITableViewCell *)cell {
    UISwitch *switchView = nil;
    if (cell != nil) {
        UIListContentView *contentView = (UIListContentView *)cell.contentView;
        switchView = [contentView viewWithTag:kCHFormSwitchViewTag];
        if (switchView == nil) {
            switchView = [UISwitch new];
            [contentView addSubview:switchView];
            switchView.translatesAutoresizingMaskIntoConstraints = NO;
            [contentView addConstraints:@[
                [switchView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:8],
                [switchView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-8],
                [switchView.rightAnchor constraintEqualToAnchor:contentView.secondaryTextLayoutGuide.rightAnchor],
            ]];
            [switchView addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            switchView.tag = kCHFormSwitchViewTag;
        }
    }
    return switchView;
}


@end
