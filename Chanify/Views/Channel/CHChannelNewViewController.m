//
//  CHChannelNewViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelNewViewController.h"
#import <XLForm/XLForm.h>
#import "CHUserDataSource.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHChannelNewViewController () <XLFormDescriptorDelegate>

@end

@implementation CHChannelNewViewController


- (instancetype)init {
    if (self = [super init]) {
        [self initializeForm];
        UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionDone:)];
        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
        rightBarButtonItem.enabled = NO;
    }
    return self;
}

#pragma mark - Private Methods
- (void)initializeForm {
    XLFormRowDescriptor *row;
    XLFormSectionDescriptor *section;
    XLFormDescriptor *form = [XLFormDescriptor formDescriptorWithTitle:@"New Channel".localized];
    form.assignFirstResponderOnShow = YES;
    form.delegate = self;

    [form addFormSection:(section = [XLFormSectionDescriptor formSection])];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"code" rowType:XLFormRowDescriptorTypeAccount title:@"Code".localized];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"name" rowType:XLFormRowDescriptorTypeText title:@"Name".localized];
    [section addFormRow:row];

    self.form = form;
}

#pragma mark - XLFormDescriptorDelegate
-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue {
    self.navigationItem.rightBarButtonItem.enabled = (self.formValidationErrors.count <= 0);
}

#pragma mark - Action Methods
- (void)actionDone:(id)sender {
    if (self.formValidationErrors.count <= 0) {
        NSDictionary *values = self.form.formValues;
        if ([CHLogic.shared insertChannel:[values valueForKey:@"code"] name:[values valueForKey:@"name"] icon:nil]) {
            [self closeAnimated:YES completion:nil];
        } else {
            [CHRouter.shared makeToast:@"Create channel failed".localized];
        }
    }
}


@end
