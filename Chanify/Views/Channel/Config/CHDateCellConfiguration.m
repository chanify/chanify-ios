//
//  CHDateCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHDateCellConfiguration.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHDateCellContentView : UIView<UIContentView>

@property (nonatomic, copy) CHDateCellConfiguration *configuration;
@property (nonatomic, readonly, strong) UILabel *dateLabel;

- (instancetype)initWithConfiguration:(CHDateCellConfiguration *)configuration;

@end

@implementation CHDateCellContentView

- (instancetype)initWithConfiguration:(CHDateCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _configuration = nil;
        UILabel *dateLabel = [UILabel new];
        [self addSubview:(_dateLabel = dateLabel)];
        dateLabel.textColor = CHTheme.shared.minorLabelColor;
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.font = [UIFont systemFontOfSize:12];
        dateLabel.numberOfLines = 1;
        [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(CHDateCellConfiguration *)configuration {
    if (![self.configuration isEqual:configuration]) {
        _configuration = configuration;
        NSString *dateText = @"";
        NSDate *date = self.configuration.date;
        if (date != nil) {
            NSCalendar *calendar = NSCalendar.currentCalendar;
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = NSLocale.currentLocale;
            NSCalendarUnit uint = NSCalendarUnitYear|NSCalendarUnitWeekOfYear|NSCalendarUnitDay;
            NSDateComponents *c1 = [calendar components:uint fromDate:date];
            NSDateComponents *c2 = [calendar components:uint fromDate:NSDate.now];
            if ([calendar isDateInToday:date]) {
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
            dateText = [formatter stringFromDate:date];
        }
        self.dateLabel.text = dateText;
    }
}

@end

@implementation CHDateCellConfiguration

+ (instancetype)cellConfiguration:(uint64_t)mid {
    return [[self.class alloc] initWithMID:(mid > 0 ? mid - 1 : 0)];
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHDateCellContentView alloc] initWithConfiguration:self];
}

@end
