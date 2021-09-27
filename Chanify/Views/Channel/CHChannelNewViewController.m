//
//  CHChannelNewViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelNewViewController.h"
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHChannelNewViewController () <CHFormDelegate>
@end

@implementation CHChannelNewViewController

- (instancetype)init {
    if (self = [super init]) {
        [self initializeForm];
        CHBarButtonItem *rightBarButtonItem = [CHBarButtonItem itemDoneWithTarget:self action:@selector(actionDone:)];
        self.rightBarButtonItem = rightBarButtonItem;
        rightBarButtonItem.enabled = NO;
    }
    return self;
}

- (instancetype)initWithParameters:(NSDictionary *)params {
    return [self init];
}

- (CGSize)calcContentSize {
    return CGSizeMake(400, 500);
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHFormInputItem *item;
    CHForm *form = [CHForm formWithTitle:@"New Channel".localized];
    form.assignFirstResponderOnShow = YES;
    form.delegate = self;

    CHFormSection *section = [CHFormSection section];
    [form addFormSection:section];

    item = [CHFormInputItem itemWithName:@"code" title:@"Code".localized];
    item.inputType = CHFormInputTypeAccount;
    item.required = YES;
    [section addFormItem:item];
    
    item = [CHFormInputItem itemWithName:@"name" title:@"Name".localized];
    item.inputType = CHFormInputTypeText;
    [section addFormItem:item];

    [section addFormItem:[CHFormIconItem itemWithName:@"icon" title:@"Icon".localized]];
    
    self.form = form;
}

#pragma mark - CHFormDelegate
- (void)formItemValueHasChanged:(CHFormItem *)item oldValue:(id)oldValue newValue:(id)newValue {
    self.rightBarButtonItem.enabled = (self.form.errorItems.count <= 0);
}

#pragma mark - Action Methods
- (void)actionDone:(id)sender {
    if (self.form.errorItems.count <= 0) {
        NSDictionary *values = self.form.formValues;
        NSString *icon = [values valueForKey:@"icon"];
        if (icon.length <= 0) icon = nil;
        CHChannelModel *model = [CHChannelModel modelWithCode:[values valueForKey:@"code"] name:[values valueForKey:@"name"] icon:icon];
        if (model != nil && [CHLogic.shared insertChannel:model]) {
            [self closeAnimated:YES completion:nil];
        } else {
            [CHRouter.shared makeToast:@"Create channel failed".localized];
        }
    }
}


@end
