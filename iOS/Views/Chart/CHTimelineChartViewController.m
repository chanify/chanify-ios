//
//  CHTimelineChartViewController.m
//  iOS
//
//  Created by WizJin on 2021/8/23.
//

#import "CHTimelineChartViewController.h"
#import "CHMessageModel.h"
#import "CHUserDataSource.h"
#import "CHLogic.h"

@interface CHTimelineChartViewController ()

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
}


@end
