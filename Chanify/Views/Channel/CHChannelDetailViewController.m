//
//  CHChannelDetailViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelDetailViewController.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHChannelModel.h"
#import "CHCrpyto.h"
#import "CHLogic.h"
#import "CHTP.pbobjc.h"

@interface CHChannelDetailViewController ()

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) NSString *token;

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
    
    NSCalendar *calender = NSCalendar.currentCalendar;
    NSDate *date = [calender dateBySettingHour:0 minute:0 second:0 ofDate:NSDate.now options:NSCalendarMatchFirst];
    date = [date dateByAddingTimeInterval:NSCalendar.currentCalendar.timeZone.secondsFromGMT + 30*24*60*60];

    CHTPToken *tk = [CHTPToken new];
    tk.expires = date.timeIntervalSince1970;
    tk.userId = CHLogic.shared.me.uid;
    tk.channel = [NSData dataFromBase64:self.model.cid];

    NSData *token = tk.data;
    NSData *key = [CHLogic.shared.nsDataSource keyForUID:tk.userId];
    NSData *sign = [CHCrpyto hmacSha256:token secret:[key subdataWithRange:NSMakeRange(0, 256/8)]];
    _token = [NSString stringWithFormat:@"%@.%@", token.base64, sign.base64];

    CHLogI("token: %s", self.token.cstr);
}


@end
