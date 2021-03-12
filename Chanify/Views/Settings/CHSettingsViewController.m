//
//  CHSettingsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSettingsViewController.h"
#import "CHNotification.h"
#import "CHLogic.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHSettingsViewController () <CHNotificationDelegate>

@end

@implementation CHSettingsViewController

- (instancetype)init {
    if (self = [super init]) {
        [CHNotification.shared addDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [CHNotification.shared removeDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.form == nil) {
        [self initializeForm];
    }
}

#pragma mark - CHNotificationDelegate
- (void)notificationStatusChanged {
    [self updateNotificationItem];
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHFormItem *item;
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:self.title];
    // ACCOUNT
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"ACCOUNT".localized])];
    item = [CHFormCodeItem itemWithName:@"user" title:@"User".localized value:CHLogic.shared.me.uid];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/user-info" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    item = [CHFormCodeItem itemWithName:@"device" title:@"Device".localized value:CHDevice.shared.uuid.hex];
    item.action = ^(CHFormItem *itm) {};
    [section addFormItem:item];
    
    //GENERAL
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"GENERAL".localized])];
    item = [CHFormSelectorItem itemWithName:@"appearance" title:@"Appearance".localized options:@[
        [CHFormOption formOptionWithValue:@(UIUserInterfaceStyleUnspecified) title:@"Default".localized],
        [CHFormOption formOptionWithValue:@(UIUserInterfaceStyleLight) title:@"Light".localized],
        [CHFormOption formOptionWithValue:@(UIUserInterfaceStyleDark) title:@"Dark".localized],
    ]];
    CHFormSelectorItem *selectItem = (CHFormSelectorItem *)item;
    selectItem.selected = @(CHTheme.shared.userInterfaceStyle);
    selectItem.onChanged = ^(CHFormItem *item, id oldValue, id newValue) {
        CHTheme.shared.userInterfaceStyle = [newValue integerValue];
    };
    [section addFormItem:item];
    
    item = [CHFormValueItem itemWithName:@"notification" title:@"Notification".localized value:@""];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/openurl" withParams:@{ @"url": UIApplicationOpenSettingsURLString, @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    // HELP
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"HELP".localized])];
    item = [CHFormValueItem itemWithName:@"quick" title:@"Quick Start".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@kQuickStartURL withParams:@{ @"title": @"Quick Start".localized, @"show": @"detail" }];
    };
    [section addFormItem:item];
//    item = [CHFormValueItem itemWithName:@"manual" title:@"Usage Manual".localized];
//    item.action = ^(CHFormItem *itm) {
//        [CHRouter.shared routeTo:@kUsageManualURL withParams:@{ @"title": @"Usage Manual".localized, @"show": @"detail" }];
//    };
//    [section addFormItem:item];

    // ABOUT
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"ABOUT".localized])];
    item = [CHFormValueItem itemWithName:@"version" title:@"Version".localized value:CHDevice.shared.version];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"privacy" title:@"Privacy Policy".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/privacy" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"acknowledgements" title:@"Acknowledgements".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/acknowledgements" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"contact-us" title:@"Contact Us".localized];
    item.hidden = [NSPredicate predicateWithObject:CHRouter.shared attribute:@"canSendMail" expected:@NO];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/sendemail" withParams:@{ @"email": @kCHContactEmail, @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    // Logout
    [form addFormSection:(section = [CHFormSection section])];
    item = [CHFormButtonItem itemWithName:@"logout" title:@"Logout".localized action:^(CHFormItem *itm) {
        [CHRouter.shared showIndicator:YES];
        [CHLogic.shared logoutWithCompletion:^(CHLCode result) {
            [CHRouter.shared showIndicator:NO];
            if (result == CHLCodeOK) {
                [CHRouter.shared routeTo:@"/page/main"];
            } else {
                [CHRouter.shared makeToast:@"Logout failed".localized];
            }
        }];
    }];
    [section addFormItem:item];

    self.form = form;
    
    [self updateNotificationItem];
}

- (void)updateNotificationItem {
    CHFormSelectorItem *item = (CHFormSelectorItem *)[self.form formItemWithName:@"notification"];
    if (item != nil) {
        item.value = (CHNotification.shared.enabled ? @"Enable".localized : @"Disable".localized);
        [self reloadItem:item];
    }
}


@end
