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
#import "CHNodeModel.h"
#import "CHCrpyto.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"
#import "CHTP.pbobjc.h"

@interface CHChannelDetailViewController ()

@property (nonatomic, readonly, strong) CHChannelModel *model;

@end

@implementation CHChannelDetailViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource channelWithCID:[params valueForKey:@"cid"]];
        [self initializeForm];
    }
    return self;
}

- (void)dealloc {
    if (self.model.type == CHChanTypeUser) {
        BOOL needUpdate = NO;
        NSString *name = [self.form.formValues valueForKey:@"name"];
        if (![self.model.name isEqualToString:name]) {
            self.model.name = name;
            needUpdate = YES;
        }
        NSString *icon = [self.form.formValues valueForKey:@"icon"];
        if (![(self.model.icon?:@"") isEqualToString:icon]) {
            self.model.icon = (icon.length > 0 ? icon : nil);
            needUpdate = YES;
        }
        if (needUpdate) {
            [CHLogic.shared updateChannel:self.model];
        }
    }
}

- (BOOL)isEqualToViewController:(CHChannelDetailViewController *)rhs {
    return [self.model isEqual:rhs.model];
}

#pragma mark - Private Methods
- (void)initializeForm {
    NSCalendar *calender = NSCalendar.currentCalendar;
    NSDate *date = [calender dateBySettingHour:0 minute:0 second:0 ofDate:NSDate.now options:NSCalendarMatchFirst];
    date = [date dateByAddingTimeInterval:NSCalendar.currentCalendar.timeZone.secondsFromGMT + 90*24*60*60];

    NSString *cid = self.model.cid;

    NSData *channel = [NSData dataFromBase64:cid];

    CHTPToken *tk = [CHTPToken new];
    tk.expires = date.timeIntervalSince1970;
    tk.userId = CHLogic.shared.me.uid;
    tk.channel = channel;

    CHTPChannel *chan = [CHTPChannel parseFromData:channel error:nil];
    if (chan.type == CHTPChanType_Sys && chan.code == CHTPChanCode_Device) {
        tk.deviceId = CHDevice.shared.uuid;
    }
    
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Channel Detail".localized];
    
    [form addFormSection:(section = [CHFormSection section])];
    if (self.model.type == CHChanTypeSys) {
        [section addFormItem:[CHFormValueItem itemWithName:@"name" title:@"Name".localized value:self.model.title]];
    } else if (self.model.type == CHChanTypeUser) {
        [section addFormItem:[CHFormValueItem itemWithName:@"code" title:@"Code".localized value:self.model.code]];
        [section addFormItem:[CHFormInputItem itemWithName:@"name" title:@"Name".localized value:self.model.name]];
        [section addFormItem:[CHFormIconItem itemWithName:@"icon" title:@"Icon".localized value:self.model.icon]];
    }

    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"Token".localized])];
    for (CHNodeModel *model in [CHLogic.shared.userDataSource loadNodes]) {
        if ([model.nid isEqualToString:@"sys"]) {
            tk.nodeId = nil;
        } else {
            tk.nodeId = model.nid;
        }
        NSData *token = tk.data;
        NSData *key = [CHLogic.shared.nsDataSource keyForUID:tk.userId];
        NSData *sign = [CHCrpyto hmacSha256:token secret:[key subdataWithRange:NSMakeRange(0, 256/8)]];
        NSString *tokenValue = [NSString stringWithFormat:@"%@.%@", token.base64, sign.base64];
        
        CHFormCodeItem *item = [CHFormCodeItem itemWithName:[@"token." stringByAppendingString:model.nid] title:model.name value:tokenValue];
        item.action = ^(CHFormCodeItem *item) {
            UIPasteboard.generalPasteboard.string = item.value;
            [CHRouter.shared makeToast:@"Token copied".localized];
        };
        [section addFormItem:item];
    }
    
    if (self.model.type == CHChanTypeUser) {
        [form addFormSection:(section = [CHFormSection section])];
        CHFormButtonItem *item = [CHFormButtonItem itemWithName:@"delete" title:@"Delete channel".localized action:^(CHFormButtonItem *item) {
            [CHRouter.shared showAlertWithTitle:@"Delete this channel or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteChannel:cid];
                [CHRouter.shared popToRootViewControllerAnimated:YES];
            }];
        }];
        [section addFormItem:item];
    }

    self.form = form;
}


@end
