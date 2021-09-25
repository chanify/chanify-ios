//
//  CHChannelDetailViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelDetailViewController.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHPasteboard.h"
#import "CHCrpyto.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHToken.h"
#import "CHTheme.h"

@interface CHChannelDetailViewController ()

@property (nonatomic, readonly, strong) CHChannelModel *model;

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
        BOOL needUpdate = NO;
        NSString *name = [self.form.formValues valueForKey:@"name"];
        if (![self.model.name isEqualToString:name]) {
            self.model.name = name;
            needUpdate = YES;
        }
        NSString *icon = [self.form.formValues valueForKey:@"icon"];
        if (![(self.model.icon?:@"") isEqualToString:icon]) {
            self.model.icon = (icon.length > 0 ? icon : nil);
            needUpdate = YES;
        }
        if (needUpdate) {
            [CHLogic.shared updateChannel:self.model];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.shield"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCreateToken:)];
}

- (BOOL)isEqualWithParameters:(NSDictionary *)params {
    return [self.model.cid isEqual:[params valueForKey:@"cid"]];
}

#pragma mark - Action Methods
- (void)actionCreateToken:(id)sender {
    [CHRouter.shared routeTo:@"/page/token" withParams:@{ @"cid": self.model.cid, @"show": @"detail" }];
}

#pragma mark - Private Methods
- (void)initializeForm {
    NSString *cid = self.model.cid;

    CHToken *tk = [CHToken tokenWithTimeInterval:90*24*60*60];
    tk.channel = [NSData dataFromBase64:cid];

    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Channel Detail".localized];
    
    [form addFormSection:(section = [CHFormSection section])];
    if (self.model.type == CHChanTypeSys) {
        [section addFormItem:[CHFormValueItem itemWithName:@"name" title:@"Name".localized value:self.model.title]];
    } else if (self.model.type == CHChanTypeUser) {
        [section addFormItem:[CHFormValueItem itemWithName:@"code" title:@"Code".localized value:self.model.code]];
        [section addFormItem:[CHFormInputItem itemWithName:@"name" title:@"Name".localized value:self.model.name]];
        [section addFormItem:[CHFormIconItem itemWithName:@"icon" title:@"Icon".localized value:self.model.icon]];
    }

    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"Token".localized])];
    section.note = [NSString stringWithFormat:@"Expires at %@".localized, tk.expired.fullDayFormat];
    for (CHNodeModel *model in [CHLogic.shared.userDataSource loadNodes]) {
        tk.node = model;
        NSString *tokenValue = [tk formatString:model.nid direct:model.isStoreDevice];
        CHFormCodeItem *item = [CHFormCodeItem itemWithName:[@"token." stringByAppendingString:model.nid] title:model.name value:tokenValue];
        [section addFormItem:item];
        item.copiedName = @"Token".localized;
    }
    
    if (self.model.type == CHChanTypeUser) {
        [form addFormSection:(section = [CHFormSection section])];
        CHFormButtonItem *item = [CHFormButtonItem itemWithName:@"delete" title:@"Delete channel".localized action:^(CHFormButtonItem *item) {
            [CHRouter.shared showAlertWithTitle:@"Delete this channel or not?".localized action:@"Delete".localized handler:^{
                [CHLogic.shared deleteChannel:cid];
                [CHRouter.shared popToRootViewControllerAnimated:YES];
            }];
        }];
        [section addFormItem:item];
    }

    self.form = form;
}


@end
