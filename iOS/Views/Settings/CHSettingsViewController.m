//
//  CHSettingsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSettingsViewController.h"
#import "CHWebFileManager.h"
#import "CHNotification.h"
#import "CHLogic+iOS.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHSettingsViewController () <CHLogicDelegate, CHNotificationDelegate>

@end

@implementation CHSettingsViewController

- (instancetype)init {
    if (self = [super init]) {
        [CHLogic.shared addDelegate:self];
        [CHNotification.shared addDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
    [CHNotification.shared removeDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.form == nil) {
        [self initializeForm];
    }
    [self updateData];
}

#pragma mark - CHLogicDelegate
- (void)logicWatchStatusChanged {
    [self reloadData];
}

#pragma mark - CHNotificationDelegate
- (void)notificationStatusChanged {
    [self updateNotificationItem];
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHTheme *theme = CHTheme.shared;
    
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
    
//    item = [CHFormValueItem itemWithName:@"sound" title:@"Sound".localized value:@""];
//    item.action = ^(CHFormItem *itm) {
//        [CHRouter.shared routeTo:@"/page/sounds" withParams:@{ @"show": @"detail" }];
//    };
//    [section addFormItem:item];
    
    // Data
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"DATA".localized])];
    item = [CHFormValueItem itemWithName:@"images" title:@"Images".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/images" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"files" title:@"Files".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/files" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];

    // WATCH
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"WATCH".localized])];
    section.hidden = [NSPredicate predicateWithObject:CHLogic.shared attribute:@"hasWatch" expected:@NO];
    item = [CHFormValueItem itemWithName:@"appinstall" title:@"No watch app installed".localized];
    [(CHFormValueItem *)item setTitleTextColor: theme.minorLabelColor];
    item.hidden = [NSPredicate predicateWithObject:CHLogic.shared attribute:@"isWatchAppInstalled" expected:@YES];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/openurl" withParams:@{ @"url": @kCHWatchAppURL }];
    };
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"syncwatch" title:@"Force data sync to watch".localized];
    item.hidden = [NSPredicate predicateWithObject:form attribute:@"appinstall.isHidden" expected:@NO];
    item.action = ^(CHFormItem *itm) {
        [CHLogic.shared syncDataToWatch:YES];
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
        [CHRouter.shared showAlertWithTitle:@"Logout or not?".localized action:@"OK".localized handler:^{
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

- (void)updateData {
    CHLogic *logic = CHLogic.shared;
    CHFormValueItem *item = nil;
    NSMutableArray *items = [NSMutableArray new];
    item = (CHFormValueItem *)[self.form formItemWithName:@"images"];
    if (item != nil) {
        NSUInteger size = logic.webImageManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [items addObject:item];
        }
    }
    item = (CHFormValueItem *)[self.form formItemWithName:@"files"];
    if (item != nil) {
        NSUInteger size = logic.webFileManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [items addObject:item];
        }
    }
    [self reloadItems:items];
}


@end
