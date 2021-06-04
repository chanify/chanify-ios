//
//  NSDate+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/10.
//

#import "NSDate+CHExt.h"
#import <Foundation/Foundation.h>

@implementation NSDate (CHExt)

+ (nullable instancetype)dateFromMID:(NSString *)mid {
    if (mid.length > 0) {
        uint64_t t = mid.uint64Hex;
        if (t > 0) {
            return [NSDate dateWithTimeIntervalSince1970:t/1000000000.0];
        }
    }
    return nil;
}

- (NSString *)shortFormat {
    if (self != nil) {
        NSCalendar *calendar = NSCalendar.currentCalendar;
        NSDateFormatter *formatter = [NSDateFormatter new];
        if ([calendar isDateInToday:self]) {
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.dateStyle = NSDateFormatterNoStyle;
        } else {
            formatter.timeStyle = NSDateFormatterNoStyle;
            formatter.dateStyle = NSDateFormatterShortStyle;
            formatter.doesRelativeDateFormatting = YES;
        }
        return [formatter stringFromDate:self];
    }
    return @"";
}

- (NSString *)mediumFormat {
    if (self != nil) {
        NSCalendar *calendar = NSCalendar.currentCalendar;
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = NSLocale.currentLocale;
        NSCalendarUnit uint = NSCalendarUnitYear|NSCalendarUnitWeekOfYear|NSCalendarUnitDay;
        NSDateComponents *c1 = [calendar components:uint fromDate:self];
        NSDateComponents *c2 = [calendar components:uint fromDate:NSDate.now];
        if ([calendar isDateInToday:self]) {
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.dateStyle = NSDateFormatterNoStyle;
        } else if (c1.year != c2.year) {
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.dateStyle = NSDateFormatterMediumStyle;
        } else if (c1.weekOfYear != c2.weekOfYear) {
            [formatter setLocalizedDateFormatFromTemplate:@"MMMdd HH:mm"];
        } else if (c1.day < c2.day - 1) {
            [formatter setLocalizedDateFormatFromTemplate:@"EEE HH:mm"];
        } else {
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.doesRelativeDateFormatting = YES;
        }
        return [formatter stringFromDate:self];
    }
    return @"";
}

- (NSString *)fullDayFormat {
    if (self != nil) {
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = NSLocale.currentLocale;
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
        return [formatter stringFromDate:self];
    }
    return @"";
}


@end
