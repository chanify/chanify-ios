//
//  CHChannelDetailViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelDetailViewController.h"
#import <XLForm/XLForm.h>
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHChannelModel.h"
#import "CHCrpyto.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"
#import "CHTP.pbobjc.h"

@interface CHChannelDetailViewController () <UICollectionViewDelegate, XLFormViewControllerDelegate>

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) NSString *token;

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
        NSString *name = [self.formValues valueForKey:@"name"];
        if (![self.model.name isEqualToString:name]) {
            self.model.name = name;
            [CHLogic.shared updateChannel:self.model];
        }
    }
}

#pragma mark - XLFormViewControllerDelegate
- (void)beginEditing:(XLFormRowDescriptor *)row {
    if ([row.tag isEqualToString:@"name"]) {
        if (![[row.cellConfig valueForKey:@"textField.textAlignment"] isEqual:@(NSTextAlignmentLeft)]) {
            [row.cellConfig setValue:@(NSTextAlignmentLeft) forKey:@"textField.textAlignment"];
            [self updateFormRow:row];
        }
    }
}

- (void)endEditing:(XLFormRowDescriptor *)row {
    if ([row.tag isEqualToString:@"name"]) {
        if (![[row.cellConfig valueForKey:@"textField.textAlignment"] isEqual:@(NSTextAlignmentRight)]) {
            [row.cellConfig setValue:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
            [self updateFormRow:row];
        }
    }
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHTheme *theme = CHTheme.shared;
    
    NSCalendar *calender = NSCalendar.currentCalendar;
    NSDate *date = [calender dateBySettingHour:0 minute:0 second:0 ofDate:NSDate.now options:NSCalendarMatchFirst];
    date = [date dateByAddingTimeInterval:NSCalendar.currentCalendar.timeZone.secondsFromGMT + 30*24*60*60];

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
    NSData *token = tk.data;
    NSData *key = [CHLogic.shared.nsDataSource keyForUID:tk.userId];
    NSData *sign = [CHCrpyto hmacSha256:token secret:[key subdataWithRange:NSMakeRange(0, 256/8)]];
    _token = [NSString stringWithFormat:@"%@.%@", token.base64, sign.base64];
    
    UIFont *codeFont = [UIFont fontWithName:@kCHCodeFontName size:14];

    XLFormRowDescriptor *row;
    XLFormSectionDescriptor *section;
    XLFormDescriptor *form = [XLFormDescriptor formDescriptorWithTitle:@"Channel Detail".localized];
    [form addFormSection:(section = [XLFormSectionDescriptor formSection])];
    
    if (self.model.type == CHChanTypeSys) {
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"name" rowType:XLFormRowDescriptorTypeInfo title:@"Name".localized];
        row.value = self.model.title;
        [section addFormRow:row];
    } else if (self.model.type == CHChanTypeUser) {
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"code" rowType:XLFormRowDescriptorTypeInfo title:@"Code".localized];
        row.value = self.model.code;
        [section addFormRow:row];

        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"name" rowType:XLFormRowDescriptorTypeText title:@"Name".localized];
        [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
        [row.cellConfig setObject:theme.minorLabelColor forKey:@"textField.textColor"];
        row.value = self.model.name;
        [section addFormRow:row];
    }

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"token" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Token".localized];
    [row.cellConfig setObject:codeFont forKey:@"detailTextLabel.font"];
    row.value = self.token;
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        UIPasteboard.generalPasteboard.string = row.value;
        [CHRouter.shared makeToast:@"Token copied".localized];
    };
    [section addFormRow:row];
    
    if (self.model.type == CHChanTypeUser) {
        [form addFormSection:(section = [XLFormSectionDescriptor formSection])];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"delete" rowType:XLFormRowDescriptorTypeButton title:@"Delete channel".localized];
        [row.cellConfig setObject:theme.alertColor forKey:@"textColor"];
        row.action.formBlock = ^(XLFormRowDescriptor *row) {
            [CHRouter.shared showAlertWithTitle:@"Delete this channel or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteChannel:cid];
                [CHRouter.shared popToRootViewControllerAnimated:YES];
            }];
        };
        [section addFormRow:row];
    }

    self.form.delegate = self;
    self.form = form;
}


@end
