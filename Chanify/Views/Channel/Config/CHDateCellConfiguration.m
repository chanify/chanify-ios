//
//  CHDateCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHDateCellConfiguration.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHDateCellContentView : CHView<CHContentView>

@property (nonatomic, copy) CHDateCellConfiguration *configuration;
@property (nonatomic, readonly, strong) CHLabel *dateLabel;

- (instancetype)initWithConfiguration:(CHDateCellConfiguration *)configuration;

@end

@implementation CHDateCellContentView

- (instancetype)initWithConfiguration:(CHDateCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _configuration = nil;
        CHLabel *dateLabel = [CHLabel new];
        [self addSubview:(_dateLabel = dateLabel)];
        dateLabel.textColor = CHTheme.shared.minorLabelColor;
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.font = [CHFont systemFontOfSize:12];
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
        self.dateLabel.text = self.configuration.date.mediumFormat;
    }
}

@end

@implementation CHDateCellConfiguration

+ (instancetype)cellConfiguration:(NSString *)mid {
    uint64_t t = mid.uint64Hex;
    return [[self.class alloc] initWithMID:[NSString stringWithFormat:@"%016llX", (t > 0 ? t - 1 : 0)]];
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHDateCellContentView alloc] initWithConfiguration:self];
}

@end
