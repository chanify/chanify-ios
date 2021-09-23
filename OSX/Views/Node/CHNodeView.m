//
//  CHNodeView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHNodeView.h"
#import "CHUserDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic.h"
#import "CHTheme.h"
#import "CHRouter.h"
#import "CHFeature.h"

typedef NS_ENUM(NSInteger, CHNodeVCStatus) {
    CHNodeVCStatusNone      = 0,
    CHNodeVCStatusShow      = 1,
    CHNodeVCStatusNew       = 2,
    CHNodeVCStatusUpdate    = 3,
};

@interface CHNodeView ()

@property (nonatomic, readonly, assign) CHNodeVCStatus status;
@property (nonatomic, readonly, strong) CHNodeModel *model;

@end

@implementation CHNodeView

- (instancetype)initWithNID:(NSString *)nid {
    if (self = [super initWithFrame:NSZeroRect]) {
        _status = CHNodeVCStatusNone;
        [self loadNode:nid];
    }
    return self;
}

- (void)dealloc {
    if (!self.model.isSystem) {
        CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:self.model.nid];
        if (node != nil) {
            BOOL needUpdate = NO;
            NSString *icon = [self.form.formValues valueForKey:@"icon"];
            if (![(node.icon?:@"") isEqualToString:icon]) {
                node.icon = (icon.length > 0 ? icon : nil);
                needUpdate = YES;
            }
            if (needUpdate) {
                [CHLogic.shared updateNode:node];
            }
        }
    }
}

#pragma mark - Action Methods
- (void)actionRefresh:(id)sender {
    @weakify(self);
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared updateNodeInfo:self.model.nid completion:^(CHLCode result) {
        @strongify(self);
        [CHRouter.shared showIndicator:NO];
        if (result != CHLCodeOK) {
            [CHRouter.shared makeToast:@"Connect node server failed".localized];
        } else {
            [self loadNode:self.model.nid];
            [CHRouter.shared makeToast:@"Update node success".localized];
        }
    }];
}

- (void)actionAddNode {
    //@weakify(self);
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared insertNode:self.model completion:^(CHLCode result) {
        //@strongify(self);
        [CHRouter.shared showIndicator:NO];
        if (result == CHLCodeOK) {
            //[self closeAnimated:YES completion:nil];
        } else if (result == CHLCodeReject) {
            [CHRouter.shared makeToast:@"The request has been rejected".localized];
        } else {
            [CHRouter.shared makeToast:@"Add node failed".localized];
        }
    }];
}

- (void)actionUpdateNode {
    //@weakify(self);
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared insertNode:self.model completion:^(CHLCode result) {
        //@strongify(self);
        [CHRouter.shared showIndicator:NO];
        if (result != CHLCodeOK) {
            [CHRouter.shared makeToast:@"Update node failed".localized];
        } else {
            //[self closeAnimated:YES completion:nil];
        }
    }];
}

- (void)actionDeleteNode {
    //@weakify(self);
    [CHRouter.shared showAlertWithTitle:@"Delete this node or not?".localized action:@"Delete".localized handler:^{
        //@strongify(self);
        [CHLogic.shared deleteNode:self.model.nid];
        //[self closeAnimated:YES completion:nil];
    }];
}

#pragma mark - Private Methods
- (void)loadNode:(NSString *)nid {
    _model = [CHLogic.shared.userDataSource nodeWithNID:nid];
    if (_model == nil) {
        [CHRouter.shared makeToast:@"Open node server failed".localized];
    } else {
        if (!self.model.isSystem) {
            _status = CHNodeVCStatusShow;
        }
        [self initializeForm];
    }
}

- (void)initializeForm {
    self.backgroundColor = CHTheme.shared.groupedBackgroundColor;

    CHFormValueItem *item;
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Node Detail".localized];
    
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"Information".localized])];

    [section addFormItem:[CHFormValueItem itemWithName:@"name" title:@"Name".localized value:self.model.name]];
    if (!self.model.isSystem) {
        [section addFormItem:[CHFormValueItem itemWithName:@"version" title:@"Version".localized value:self.model.version]];
        [section addFormItem:(item = [CHFormCodeItem itemWithName:@"nodeid" title:@"NodeID".localized value:self.model.nid])];
        item.copiedName = @"NodeID".localized;
    }

    [section addFormItem:(item = [CHFormValueItem itemWithName:@"endpoint" title:@"Endpoint".localized value:self.model.endpoint])];
    item.copiedName = @"Endpoint URL".localized;
    if (!self.model.isSystem) {
        [section addFormItem:[CHFormIconItem itemWithName:@"icon" title:@"Icon".localized value:self.model.icon]];
    }

    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"Features".localized])];
    for (NSString *feature in self.model.features) {
        if ([feature isEqualToString:@"store.device"] && self.status != CHNodeVCStatusNone) {
            @weakify(self);
            CHFormSwitchItem *item = [CHFormSwitchItem itemWithName:feature title:feature.localized];
            item.icon = [CHFeature featureIconWithName:feature];
            item.value = @(self.model.isStoreDevice);
            item.enbaled = (self.status != CHNodeVCStatusShow);
            item.onChanged = ^(CHFormSwitchItem *item, id oldValue, NSNumber *newValue) {
                @strongify(self);
                if ([newValue boolValue]) {
                    self.model.flags |= CHNodeModelFlagsStoreDevice;
                } else {
                    self.model.flags &= ~CHNodeModelFlagsStoreDevice;
                }
            };
            [section addFormItem:item];
        } else {
            CHFormValueItem *item = [CHFormValueItem itemWithName:feature title:feature.localized];
            item.icon = [CHFeature featureIconWithName:feature];
            [section addFormItem:item];
        }
    }

    [form addFormSection:(section = [CHFormSection section])];
    @weakify(self);
    switch (self.status) {
        case CHNodeVCStatusNone:
            break;
        case CHNodeVCStatusShow:
        {
            [section addFormItem:[CHFormButtonItem itemWithName:@"delete-node" title:@"Delete node".localized action:^(CHFormItem *item){
                @strongify(self);
                [self actionDeleteNode];
            }]];
        }
            break;
        case CHNodeVCStatusNew:
        {
            [section addFormItem:[CHFormButtonItem itemWithName:@"add-node" title:@"Add node".localized action:^(CHFormItem *item){
                @strongify(self);
                [self actionAddNode];
            }]];
        }
            break;
        case CHNodeVCStatusUpdate:
        {
            [section addFormItem:[CHFormButtonItem itemWithName:@"update-node" title:@"Update node".localized action:^(CHFormItem *item){
                @strongify(self);
                [self actionUpdateNode];
            }]];
        }
            break;
    }
    self.form = form;
}


@end
