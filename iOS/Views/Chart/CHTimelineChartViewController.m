//
//  CHTimelineChartViewController.m
//  iOS
//
//  Created by WizJin on 2021/8/23.
//

#import "CHTimelineChartViewController.h"
#import <Masonry/Masonry.h>
#import "CHTimelineChartView.h"
#import "CHMessageModel.h"
#import "CHUserDataSource.h"
#import "CHLogic.h"

@interface CHTimelineChartViewController ()

@property (nonatomic, readonly, strong) CHTimelineChartView *timelineChartView;
@property (nonatomic, readonly, strong) CHMessageModel *model;

@end


@implementation CHTimelineChartViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource messageWithMID:[params valueForKey:@"mid"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.model.title;
    
    CHTimelineChartView *timelineChartView = [CHTimelineChartView new];
    [self.view addSubview:(_timelineChartView = timelineChartView)];
    [timelineChartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(200);
    }];
}


@end
