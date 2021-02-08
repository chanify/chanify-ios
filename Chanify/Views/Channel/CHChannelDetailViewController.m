//
//  CHChannelDetailViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelDetailViewController.h"
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHLogic.h"

@interface CHChannelDetailViewController ()

@property (nonatomic, readonly, strong) CHChannelModel *model;

@end

@implementation CHChannelDetailViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource channelWithCID:[params valueForKey:@"cid"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Channel Detail".localized;
}


@end
