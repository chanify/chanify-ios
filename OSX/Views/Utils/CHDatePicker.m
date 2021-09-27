//
//  CHDatePicker.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHDatePicker.h"

@implementation CHDatePicker

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.bezeled = NO;
        self.bordered = NO;
        self.presentsCalendarOverlay = YES;
    }
    return self;
}

- (void)setPreferredDatePickerStyle:(NSDatePickerStyle)preferredDatePickerStyle {
    self.datePickerStyle = preferredDatePickerStyle;
}

- (NSDatePickerStyle)preferredDatePickerStyle {
    return self.datePickerStyle;
}

- (void)setDate:(NSDate *)date {
    self.dateValue = date;
}

- (nullable NSDate *)date {
    return self.dateValue;
}

- (void)setMinimumDate:(NSDate *)minimumDate {
    self.minDate = minimumDate;
}

- (nullable NSDate *)minimumDate {
    return self.minDate;
}

- (void)setMaximumDate:(NSDate *)maximumDate {
    self.maxDate = maximumDate;
}

- (nullable NSDate *)maximumDate {
    return self.maxDate;
}

- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(CHControlEvents)controlEvents {
    self.target = target;
    self.action = action;
}


@end
