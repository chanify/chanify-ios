//
//  CHTimelineChartView.m
//  iOS
//
//  Created by WizJin on 2021/8/25.
//

#import "CHTimelineChartView.h"
#import "CHTheme.h"

@implementation CHTimelineChartView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = CHTheme.shared.cellBackgroundColor;
    }
    return self;
}


@end
