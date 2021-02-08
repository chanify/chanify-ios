//
//  CHSettingsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSettingsViewController.h"
#import <XLForm/XLForm.h>
#import "CHNotification.h"
#import "CHLogic.h"
#import "CHTheme.h"
#import "CHDevice.h"
#import "CHRouter.h"

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

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    XLFormRowDescriptor *row = [self.form formRowAtIndex:indexPath];
    if (row.rowType == XLFormRowDescriptorTypeSelectorPush && row.action.formBlock != nil) {
        row.action.formBlock(row);
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - CHNotificationDelegate
- (void)notificationStatusChanged {
    XLFormRowDescriptor *row = [self.form formRowWithTag:@"notification"];
    NSString *value = (CHNotification.shared.enabled ? @"Enable".localized : @"Disable".localized);
    if (![value isEqualToString:row.value]) {
        row.value = value;
        [self reloadFormRow:row];
    }
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHTheme *theme = CHTheme.shared;

    XLFormRowDescriptor *row;
    XLFormSectionDescriptor *section;
    XLFormDescriptor *form = [XLFormDescriptor formDescriptorWithTitle:self.title];

    UIFont *codeFont = [UIFont fontWithName:@kCHCodeFontName size:14];

    // ACCOUNT
    [form addFormSection:(section = [XLFormSectionDescriptor formSectionWithTitle:@"ACCOUNT".localized])];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"user" rowType:XLFormRowDescriptorTypeSelectorPush title:@"User".localized];
    [row.cellConfig setObject:codeFont forKey:@"detailTextLabel.font"];
    row.value = fixSubStr(CHLogic.shared.me.uid);
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared routeTo:@"/page/user-info"];
    };
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"device" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Device".localized];
    [row.cellConfig setObject:codeFont forKey:@"detailTextLabel.font"];
    row.value = fixSubStr(CHDevice.shared.uuid.hex);
    [section addFormRow:row];

    // GENERAL
    [form addFormSection:(section = [XLFormSectionDescriptor formSectionWithTitle:@"GENERAL".localized])];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"appearance" rowType:XLFormRowDescriptorTypeSelectorActionSheet title:@"Appearance".localized];
    row.cellConfig[@"accessoryType"] = @(UITableViewCellAccessoryDisclosureIndicator);
    row.selectorOptions = @[
        [XLFormOptionsObject formOptionsObjectWithValue:@(UIUserInterfaceStyleUnspecified) displayText:@"Default".localized],
        [XLFormOptionsObject formOptionsObjectWithValue:@(UIUserInterfaceStyleLight) displayText:@"Light".localized],
        [XLFormOptionsObject formOptionsObjectWithValue:@(UIUserInterfaceStyleDark) displayText:@"Dark".localized],
    ];
    for (XLFormOptionsObject *option in row.selectorOptions) {
        if ([option.formValue integerValue] == theme.userInterfaceStyle) {
            [row setValue:option];
            row.value = option;
            [self reloadFormRow:row];
            break;
        }
    }
    row.onChangeBlock = ^(id oldValue, XLFormOptionsObject *newValue, XLFormRowDescriptor *rowDescriptor) {
        CHTheme.shared.userInterfaceStyle = [newValue.formValue integerValue];
    };
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"notification" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Notification".localized];
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared routeTo:@"/action/openurl" withParams:@{ @"url": UIApplicationOpenSettingsURLString }];
    };
    [section addFormRow:row];
    
    // ABOUT
    [form addFormSection:(section = [XLFormSectionDescriptor formSectionWithTitle:@"ABOUT".localized])];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"version" rowType:XLFormRowDescriptorTypeInfo title:@"Version".localized];
    row.value = CHDevice.shared.version;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"privacy" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Privacy Policy".localized];
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared routeTo:@kCHPrivacyURL withParams:@{ @"title": @"Privacy Policy".localized }];
    };
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"acknowledgements" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Acknowledgements".localized];
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared routeTo:@"/page/acknowledgements"];
    };
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"contact-us" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Contact Us".localized];
    row.hidden = [NSPredicate predicateWithObject:CHRouter.shared attribute:@"canSendMail" expected:@NO];
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared routeTo:@"/action/sendemail" withParams:@{ @"email": @kCHContactEmail }];
    };
    [section addFormRow:row];

#ifdef DEBUG
    [form addFormSection:(section = [XLFormSectionDescriptor formSectionWithTitle:@"DEBUG"])];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"reset" rowType:XLFormRowDescriptorTypeButton title:@"Reset"];
    [row.cellConfig setObject:theme.alertColor forKey:@"textColor"];
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared showIndicator:YES];
        [CHLogic.shared resetData];
        dispatch_main_after(1.0, ^{
            exit(0);
        });
    };
    [section addFormRow:row];
#endif
    
    // Logout
    [form addFormSection:(section = [XLFormSectionDescriptor formSection])];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"logout" rowType:XLFormRowDescriptorTypeButton title:@"Logout".localized];
    [row.cellConfig setObject:theme.alertColor forKey:@"textColor"];
    row.action.formBlock = ^(XLFormRowDescriptor *row) {
        [CHRouter.shared showIndicator:YES];
        [CHLogic.shared logoutWithCompletion:^(CHLCode result) {
            [CHRouter.shared showIndicator:NO];
            if (result == CHLCodeOK) {
                [CHRouter.shared routeTo:@"/page/main"];
            } else {
                [CHRouter.shared makeToast:@"Logout failed".localized];
            }
        }];
    };
    [section addFormRow:row];

    self.form = form;
}

- (void)updateRowHiddenWithTag:(NSString *)tag {
    if (self.form != nil) {
        XLFormRowDescriptor *row = [self.form formRowWithTag:tag];
        [row setHidden:row.hidden];
    }
}

static inline NSString *fixSubStr(NSString *val) {
    if (val.length <= 20) {
        return val;
    }
    return [[val substringToIndex:20] stringByAppendingString:@"…"];
}


@end
