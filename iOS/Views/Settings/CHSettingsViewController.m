//
//  CHSettingsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSettingsViewController.h"
#import "CHNotification.h"
#import "CHWebFileManager.h"
#import "CHWebImageManager.h"
#import "CHWebAudioManager.h"
#import "CHWebLinkManager.h"
#import "CHNSDataSource.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHSettingsViewController () <CHLogicDelegate, CHNotificationDelegate, CHWebCacheManagerDelegate>

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CHLogic *logic = CHLogic.shared;
    [logic.webFileManager addDelegate:self];
    [logic.webImageManager addDelegate:self];
    [logic.webAudioManager addDelegate:self];
    [logic.webLinkManager addDelegate:self];
    [self webCacheAllocatedFileSizeChanged:logic.webFileManager];
    [self webCacheAllocatedFileSizeChanged:logic.webImageManager];
    [self webCacheAllocatedFileSizeChanged:logic.webAudioManager];
    [self webCacheAllocatedFileSizeChanged:logic.webLinkManager];
}

- (void)viewDidDisappear:(BOOL)animated {
    CHLogic *logic = CHLogic.shared;
    [logic.webFileManager removeDelegate:self];
    [logic.webImageManager removeDelegate:self];
    [logic.webAudioManager removeDelegate:self];
    [logic.webLinkManager removeDelegate:self];
    [super viewDidDisappear:animated];
}

#pragma mark - CHLogicDelegate
- (void)logicWatchStatusChanged {
    [self reloadData];
}

- (void)logicNotificationSoundChanged {
    CHFormValueItem *item = (CHFormValueItem *)[self.form formItemWithName:@"sound"];
    item.value = CHLogic.shared.defaultNotificationSound;
    [self reloadItem:item];
}

#pragma mark - CHNotificationDelegate
- (void)notificationStatusChanged {
    [self updateNotificationItem];
}

#pragma mark - CHWebCacheManagerDelegate
- (void)webCacheAllocatedFileSizeChanged:(CHWebCacheManager *)manager {
    CHLogic *logic = CHLogic.shared;
    if (manager == logic.webImageManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.form formItemWithName:@"images"];
        NSUInteger size = logic.webImageManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self reloadItem:item];
        }
    } else if (manager == logic.webAudioManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.form formItemWithName:@"audios"];
        NSUInteger size = logic.webAudioManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self reloadItem:item];
        }
    } else if (manager == logic.webFileManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.form formItemWithName:@"files"];
        NSUInteger size = logic.webFileManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self reloadItem:item];
        }
    } else if (manager == logic.webLinkManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.form formItemWithName:@"links"];
        NSUInteger size = logic.webLinkManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self reloadItem:item];
        }
    }
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHLogic *logic = CHLogic.shared;
    CHTheme *theme = CHTheme.shared;
    
    CHFormItem *item;
    CHFormSelectorItem *selectItem;
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:self.title];

    // ACCOUNT
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"ACCOUNT".localized])];
    item = [CHFormCodeItem itemWithName:@"user" title:@"User".localized value:logic.me.uid];
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
    selectItem = (CHFormSelectorItem *)item;
    selectItem.selected = @(theme.userInterfaceStyle);
    selectItem.onChanged = ^(CHFormItem *item, id oldValue, id newValue) {
        CHTheme.shared.userInterfaceStyle = [newValue integerValue];
    };
    [section addFormItem:item];
    
    item = [CHFormValueItem itemWithName:@"notification" title:@"Notification".localized value:@""];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/openurl" withParams:@{ @"url": UIApplicationOpenSettingsURLString, @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    item = [CHFormValueItem itemWithName:@"sound" title:@"Sound".localized
                                   value:[logic.nsDataSource notificationSoundForUID:logic.me.uid]];
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSString *value) {
        return value.length > 0 ? value : @"default".localized;
    }];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/sounds" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    if (@available(iOS 15.0, *)) {
        item = [CHFormSelectorItem itemWithName:@"banner-icon-mode" title:@"Banner Icon".localized options:@[
            [CHFormOption formOptionWithValue:@(CHBannerIconModeNone) title:@"None".localized],
            [CHFormOption formOptionWithValue:@(CHBannerIconModeChan) title:@"Channel".localized],
            [CHFormOption formOptionWithValue:@(CHBannerIconModeNode) title:@"Node".localized],
        ]];
        selectItem = (CHFormSelectorItem *)item;
        selectItem.selected = @([logic.nsDataSource bannerIconModeForUID:logic.me.uid]);
        selectItem.onChanged = ^(CHFormItem *item, id oldValue, id newValue) {
            CHLogic *logic = CHLogic.shared;
            [logic.nsDataSource updateBannerIconMode:[newValue integerValue] uid:logic.me.uid];
        };
        [section addFormItem:item];
    }

    // SECURITY
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"SECURITY".localized])];
    item = [CHFormValueItem itemWithName:@"blocklist" title:@"Token blocklist".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/blocklist" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    // DATA
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"DATA".localized])];
    
    item = [CHFormSelectorItem itemWithName:@"download-mode" title:@"Download Mode".localized options:@[
        [CHFormOption formOptionWithValue:@(CHLogicDownloadModeAuto) title:@"Auto".localized],
        [CHFormOption formOptionWithValue:@(CHLogicDownloadModeManual) title:@"Manual".localized],
        [CHFormOption formOptionWithValue:@(CHLogicDownloadModeWifiOnly) title:@"Wi-Fi only".localized],
    ]];
    selectItem = (CHFormSelectorItem *)item;
    selectItem.selected = @(CHLogic.shared.downloadMode);
    selectItem.onChanged = ^(CHFormItem *item, id oldValue, id newValue) {
        CHLogic.shared.downloadMode = [newValue integerValue];
    };
    [section addFormItem:item];

    item = [CHFormValueItem itemWithName:@"images" title:@"Images".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/images" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"audios" title:@"Audios".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/audios" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"files" title:@"Files".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/files" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"links" title:@"Links".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/links" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];

    // WATCH
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"WATCH".localized])];
    section.hidden = [NSPredicate predicateWithObject:logic attribute:@"hasWatch" expected:@NO];
    item = [CHFormValueItem itemWithName:@"appinstall" title:@"No watch app installed".localized];
    [(CHFormValueItem *)item setTitleTextColor: theme.minorLabelColor];
    item.hidden = [NSPredicate predicateWithObject:logic attribute:@"isWatchAppInstalled" expected:@YES];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/openurl" withParams:@{ @"url": @kCHWatchAppURL }];
    };
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"syncwatch" title:@"Force data sync to watch".localized];
    item.hidden = [NSPredicate predicateWithObject:form attribute:@"appinstall.isHidden" expected:@NO];
    item.action = ^(CHFormItem *itm) {
        if ([CHLogic.shared syncDataToWatch:YES]) {
            [CHRouter.shared makeToast:@"Send data to watch success".localized];
        } else {
            [CHRouter.shared makeToast:@"Send data to watch failed".localized];
        }
    };
    [section addFormItem:item];
    
    // PERSONALIZE
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"PERSONALIZE".localized])];
    item = [CHFormValueItem itemWithName:@"actions" title:@"Action Scripts".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/action-scripts" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    // HELP
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"HELP".localized])];
    item = [CHFormValueItem itemWithName:@"quick" title:@"Quick Start".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@kQuickStartURL withParams:@{ @"title": @"Quick Start".localized, @"show": @"detail" }];
    };
    [section addFormItem:item];

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
    
    // LOGOUT
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


@end
