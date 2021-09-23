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

@interface CHNodeView ()

@property (nonatomic, readonly, strong) CHNodeModel *model;

@end

@implementation CHNodeView

- (instancetype)initWithNID:(NSString *)nid {
    if (self = [super initWithFrame:NSZeroRect]) {
        _nid = nid;
        _model = [CHLogic.shared.userDataSource nodeWithNID:nid];

        self.backgroundColor = CHTheme.shared.groupedBackgroundColor;

        CHFormItem *item;
        CHFormSection *section;
        CHForm *form = [CHForm formWithTitle:self.model.name];
        
        [form addFormSection:(section = [CHFormSection sectionWithTitle:@"ABOUT".localized])];
        item = [CHFormValueItem itemWithName:@"version" title:@"Version".localized value:@"1.0.0"];
        [section addFormItem:item];
        
        item = [CHFormValueItem itemWithName:@"test" title:@"Test".localized value:@"abcdef"];
        [section addFormItem:item];
        
        self.form = form;
    }
    return self;
}


@end
