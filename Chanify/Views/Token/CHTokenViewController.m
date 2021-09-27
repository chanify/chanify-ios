//
//  CHTokenViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/17.
//

#import "CHTokenViewController.h"
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHRouter.h"
#import "CHToken.h"
#import "CHLogic.h"

@interface CHTokenViewController ()

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) CHFormSection *tokenSection;

@end

@implementation CHTokenViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource channelWithCID:[params valueForKey:@"cid"]];
        [self initializeForm];
    }
    return self;
}

#pragma mark - Private Methods
- (void)initializeForm{
    @weakify(self);
    
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Generate Token".localized];
    
    [form addFormSection:(section = [CHFormSection section])];
    [section addFormItem:[CHFormValueItem itemWithName:@"channel" title:@"Channel".localized value:self.model.title]];
    
    NSTimeInterval day = 60*60*24;
    NSDate *select = [NSDate dateWithTimeIntervalSinceNow:day*90];
    CHFormDateItem *dateItem = [CHFormDateItem itemWithName:@"expire" title:@"Expire".localized value:select];
    [section addFormItem:dateItem];
    dateItem.minimumDate = [NSDate dateWithTimeIntervalSinceNow:day];
    dateItem.maximumDate = [NSDate dateWithTimeIntervalSinceNow:day*365*5];
    dateItem.onChanged = ^(CHFormDateItem *item, NSDate *oldValue, NSDate *newValue) {
        if (![oldValue isEqualToDate:newValue]) {
            @strongify(self);
            [self updateDate:newValue];
        }
    };
    [form addFormSection:(_tokenSection = [CHFormSection sectionWithTitle:@"Token".localized])];
    for (CHNodeModel *model in [CHLogic.shared.userDataSource loadNodes]) {
        CHFormCodeItem *item = [CHFormCodeItem itemWithName:[@"token." stringByAppendingString:model.nid] title:model.name value:@""];
        [self.tokenSection addFormItem:item];
        item.copiedName = @"Token".localized;
    }
    self.form = form;
    
    [self updateDate:select];
}

- (void)updateDate:(NSDate *)date {
    CHToken *tk = [CHToken tokenWithDate:date];
    tk.channel = [NSData dataFromBase64:self.model.cid];
    for (CHNodeModel *model in [CHLogic.shared.userDataSource loadNodes]) {
        CHFormCodeItem *item = [self.tokenSection itemWithName:[@"token." stringByAppendingString:model.nid]];
        if (item != nil) {
            tk.node = model;
            item.value = [tk formatString:model.nid direct:model.isStoreDevice];
        }
    }
    self.tokenSection.note = [NSString stringWithFormat:@"Expires at %@".localized, tk.expired.fullDayFormat];
    [self reloadSection:self.tokenSection];
}


@end
