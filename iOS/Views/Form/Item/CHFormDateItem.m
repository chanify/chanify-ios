//
//  CHFormDateItem.m
//  iOS
//
//  Created by WizJin on 2021/5/17.
//

#import "CHFormDateItem.h"
#import "CHFormViewController.h"

@implementation CHFormDateItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:value]) {
        _required = NO;
    }
    return self;
}

- (void)prepareCell:(UITableViewCell *)cell {
    [super prepareCell:cell];
    UIDatePicker *datePicker = [self datePickerForCell:cell];
    if (datePicker != nil) {
        datePicker.minimumDate = self.minimumDate;
        datePicker.maximumDate = self.maximumDate;
        datePicker.date = self.value ?: NSDate.now;
    }
}

- (UITableViewCellAccessoryType)accessoryType {
    return UITableViewCellAccessoryNone;
}

- (__kindof NSString *)textValue {
    return @"";
}

#pragma mark - Action Methods
- (void)valueChanged:(UIDatePicker *)sender {
    NSDate *old = self.value;
    if (![old isEqualToDate:sender.date]) {
        self.value = sender.date;
        [self.section.form notifyItemValueHasChanged:self oldValue:old newValue:self.value];
    }
}

#pragma mark - Private Methods
- (nullable UIDatePicker *)datePickerForCell:(nullable UITableViewCell *)cell {
    UIDatePicker *datePicker = nil;
    if (cell != nil) {
        UIListContentView *contentView = (UIListContentView *)cell.contentView;
        datePicker = [contentView viewWithTag:kCHFormDatePickerTag];
        if (datePicker == nil) {
            datePicker = [UIDatePicker new];
            [contentView addSubview:datePicker];
            datePicker.translatesAutoresizingMaskIntoConstraints = NO;
            [contentView addConstraints:@[
                [datePicker.centerYAnchor constraintEqualToAnchor:contentView.centerYAnchor],
                [datePicker.rightAnchor constraintEqualToAnchor:contentView.secondaryTextLayoutGuide.rightAnchor],
            ]];
            [datePicker addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
            datePicker.datePickerMode = UIDatePickerModeDate;
            datePicker.tag = kCHFormDatePickerTag;
        }
    }
    return datePicker;
}


@end
