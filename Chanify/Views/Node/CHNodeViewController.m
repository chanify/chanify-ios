//
//  CHNodeViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeViewController.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHCrpyto.h"

typedef NS_ENUM(NSInteger, CHNodeVCStatus) {
    CHNodeVCStatusNone      = 0,
    CHNodeVCStatusShow      = 1,
    CHNodeVCStatusNew       = 2,
    CHNodeVCStatusUpdate    = 3,
};

@interface CHNodeViewController () <UITableViewDelegate>

@property (nonatomic, readonly, assign) CHNodeVCStatus status;
@property (nonatomic, readonly, strong) CHNodeModel *model;

@end

@implementation CHNodeViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _status = CHNodeVCStatusNone;
        NSString *endpoint = [params valueForKey:@"endpoint"];
        if (endpoint.length > 0) {
            [CHRouter.shared showIndicator:YES];
            NSURL *url = [NSURL URLWithString:@"/rest/v1/info" relativeToURL:[NSURL URLWithString:endpoint]];
            NSDictionary *info = [NSDictionary dictionaryWithJSONData:[NSData dataWithContentsOfURL:url]];
            [CHRouter.shared showIndicator:NO];
            if (info.count > 0) {
                NSString *nid = [info valueForKey:@"nodeid"];
                if (nid.length > 0) {
                    _model = [CHNodeModel modelWithNID:nid name:[info valueForKey:@"name"] endpoint:[info valueForKey:@"endpoint"] flags:0 features:[[info valueForKey:@"features"] componentsJoinedByString:@","]];
                    CHNodeModel *model = [CHLogic.shared.userDataSource nodeWithNID:nid];
                    if (model == nil) {
                        _status = CHNodeVCStatusNew;
                    } else {
                        self.model.flags = model.flags;
                        _status = CHNodeVCStatusUpdate;
                    }
                }
            }
        }
        if (_model == nil) {
            NSString *nid = [params valueForKey:@"nid"];
            if (nid.length > 0) {
                _model = [CHLogic.shared.userDataSource nodeWithNID:nid];
                _status = CHNodeVCStatusShow;
            }
        }
        if (_model != nil) {
            if ([self.model.nid isEqualToString:@"sys"]) {
                _status = CHNodeVCStatusNone;
            }
        } else {
            @weakify(self);
            dispatch_main_async(^{
                @strongify(self);
                [self closeAnimated:YES completion:nil];
                [CHRouter.shared makeToast:@"Connect node server failed".localized];
            });
        }
        [self initializeForm];
    }
    return self;
}

- (BOOL)isEqualToViewController:(CHNodeViewController *)rhs {
    return [self.model isEqual:rhs.model];
}

#pragma mark - Action Methods
- (void)actionAddNode {
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared insertNode:self.model completion:^(CHLCode result) {
        [CHRouter.shared showIndicator:NO];
        if (result != CHLCodeOK) {
            [CHRouter.shared makeToast:@"Add node failed".localized];
        } else {
            [self closeAnimated:YES completion:nil];
        }
    }];
}

- (void)actionUpdateNode {
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared insertNode:self.model completion:^(CHLCode result) {
        [CHRouter.shared showIndicator:NO];
        if (result != CHLCodeOK) {
            [CHRouter.shared makeToast:@"Update node failed".localized];
        } else {
            [self closeAnimated:YES completion:nil];
        }
    }];
}

- (void)actionDeleteNode {
    [CHLogic.shared deleteNode:self.model.nid];
    [self closeAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (void)initializeForm {
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Node Detail".localized];
    
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"Information".localized])];
    [section addFormItem:[CHFormValueItem itemWithName:@"name" title:@"Name".localized value:self.model.name]];
    [section addFormItem:[CHFormValueItem itemWithName:@"endpoint" title:@"Endpoint".localized value:self.model.endpoint]];

    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"Features".localized])];
    for (NSString *feature in self.model.features) {
        if ([feature isEqualToString:@"store.device"] && self.status != CHNodeVCStatusNone) {
            @weakify(self);
            CHFormSwitchItem *item = [CHFormSwitchItem itemWithName:feature title:feature.localized];
            item.icon = [self featureIconWithName:feature];
            item.value = @(self.model.flags & CHNodeModelFlagsStoreDevice);
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
            item.icon = [self featureIconWithName:feature];
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

- (UIImage *)featureIconWithName:(NSString *)name {
    static NSDictionary<NSString *, NSString *> *iconTable;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iconTable = @{
            @"msg.text": @"doc.plaintext",
            @"msg.image": @"photo",
            @"msg.video": @"video",
            @"msg.audio": @"waveform",
            @"msg.timeline": @"waveform.path.ecg",
            @"store.device": @"externaldrive.badge.person.crop",
        };
    });
    NSString *image = [iconTable objectForKey:name];
    if (image.length > 0) {
        return [UIImage systemImageNamed:image];
    }
    return nil;
}


@end
