//
//  CHDatePicker.h
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

#define CHDatePickerModeDate        NSDatePickerModeSingle
#define CHDatePickerStyleCompact    NSDatePickerStyleTextFieldAndStepper

@interface CHDatePicker : NSDatePicker

@property (nonatomic, assign) NSDatePickerStyle preferredDatePickerStyle;
@property (nonatomic, nullable, strong) NSDate *minimumDate;
@property (nonatomic, nullable, strong) NSDate *maximumDate;
@property (nonatomic, nullable, strong) NSDate *date;

- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(CHControlEvents)controlEvents;


@end

NS_ASSUME_NONNULL_END
