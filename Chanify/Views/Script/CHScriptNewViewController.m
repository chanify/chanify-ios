//
//  CHScriptNewViewController.m
//  iOS
//
//  Created by WizJin on 2022/4/1.
//

#import "CHScriptNewViewController.h"
#import "CHScriptViewController.h"
#import "CHScriptModel.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHScriptNewViewController () <CHFormDelegate, CHScriptViewControllerDelegate>

@property (nonatomic, nullable, strong) NSString *script;

@end

@implementation CHScriptNewViewController

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
    CHForm *form = [CHForm formWithTitle:@"New Script".localized];
    form.assignFirstResponderOnShow = YES;
    form.delegate = self;
    
    CHFormSection *section = [CHFormSection section];
    [form addFormSection:section];
    
    CHFormInputItem *input = [CHFormInputItem itemWithName:@"name" title:@"Name".localized];
    input.inputType = CHFormInputTypeAccount;
    input.required = YES;
    [section addFormItem:input];

    CHFormSelectorItem *selectItem = [CHFormSelectorItem itemWithName:@"type" title:@"type".localized options:@[
        [CHFormOption formOptionWithValue:@"action" title:@"action".localized],
        [CHFormOption formOptionWithValue:@"module" title:@"module".localized],
    ]];
    selectItem.selected = @"action";
    [section addFormItem:selectItem];

    @weakify(self);
    CHFormItem *item = [CHFormValueItem itemWithName:@"script" title:@"Script".localized];
    item.action = ^(CHFormItem *itm) {
        @strongify(self);
        [self showScriptView];
    };
    [section addFormItem:item];
    
    self.form = form;
}

#pragma mark - CHFormDelegate
- (void)formItemValueHasChanged:(CHFormItem *)item oldValue:(id)oldValue newValue:(id)newValue {
    self.rightBarButtonItem.enabled = (self.form.errorItems.count <= 0);
}

#pragma mark - CHScriptViewControllerDelegate
- (void)scriptViewController:(CHScriptViewController *)vc script:(NSString *)script {
    self.script = script;
}

#pragma mark - Action Methods
- (void)actionDone:(id)sender {
    if (self.form.errorItems.count <= 0) {
        NSDictionary *values = self.form.formValues;
        NSString *name = [values valueForKey:@"name"];
        NSString *type = [values valueForKey:@"type"];
        if (name.length > 0) {
            CHScriptModel *model = [CHScriptModel modelWithName:name type:(type ?: @"action") lastupdate:NSDate.now];
            if (model != nil && [CHLogic.shared insertScript:model]) {
                [CHLogic.shared updateScript:model.name content:self.script];
                [self closeAnimated:YES completion:nil];
            } else {
                [CHRouter.shared makeToast:@"Create script failed".localized];
            }
        }
    }
}

#pragma mark - Private Methods
- (void)showScriptView {
    NSString *name = [self.form.formValues valueForKey:@"name"];
    CHScriptViewController *vc = [[CHScriptViewController alloc] initWithName:name script:self.script];
    vc.delegate = self;
    [CHRouter.shared pushViewController:vc animated:YES];
}


@end
