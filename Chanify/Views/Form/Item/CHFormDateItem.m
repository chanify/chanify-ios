//
//  CHFormDateItem.m
//  iOS
//
//  Created by WizJin on 2021/5/17.
//

#import "CHFormDateItem.h"
#import "CHForm.h"

@implementation CHFormDateItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:value]) {
        _required = NO;
    }
    return self;
}

- (void)prepareCell:(CHFormViewCell *)cell {
    [super prepareCell:cell];
    CHDatePicker *datePicker = [self datePickerForCell:cell];
    if (datePicker != nil) {
        datePicker.minimumDate = self.minimumDate;
        datePicker.maximumDate = self.maximumDate;
        datePicker.date = self.value ?: NSDate.now;
    }
}

- (CHFormViewCellAccessoryType)accessoryType {
    return CHFormViewCellAccessoryNone;
}

- (__kindof NSString *)textValue {
    return @"";
}

#pragma mark - Action Methods
- (void)valueChanged:(CHDatePicker *)sender {
    NSDate *old = self.value;
    if (![old isEqualToDate:sender.date]) {
        self.value = sender.date;
        [self.section.form notifyItemValueHasChanged:self oldValue:old newValue:self.value];
    }
}

#pragma mark - Private Methods
- (nullable CHDatePicker *)datePickerForCell:(nullable CHFormViewCell *)cell {
    CHDatePicker *datePicker = nil;
    if (cell != nil) {
        CHListContentView *contentView = (CHListContentView *)cell.contentView;
        datePicker = [contentView viewWithTag:kCHFormDatePickerTag];
        if (datePicker == nil) {
            datePicker = [CHDatePicker new];
            [contentView addSubview:datePicker];
            datePicker.translatesAutoresizingMaskIntoConstraints = NO;
            [contentView addConstraints:@[
                [datePicker.centerYAnchor constraintEqualToAnchor:contentView.centerYAnchor],
                [datePicker.rightAnchor constraintEqualToAnchor:contentView.secondaryTextLayoutGuide.rightAnchor],
            ]];
            [datePicker addTarget:self action:@selector(valueChanged:) forControlEvents:CHControlEventValueChanged];
            datePicker.preferredDatePickerStyle = CHDatePickerStyleCompact;
            datePicker.datePickerMode = CHDatePickerModeDate;
            datePicker.tagID = kCHFormDatePickerTag;
        }
    }
    return datePicker;
}


@end
