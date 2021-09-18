//
//  CHNodeView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHNodeView.h"
#import "CHFormView.h"
#import "CHUserDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHNodeView ()

@property (nonatomic, readonly, strong) CHNodeModel *model;
@property (nonatomic, readonly, strong) CHFormView *formView;

@end

@implementation CHNodeView

- (instancetype)initWithNID:(NSString *)nid {
    if (self = [super initWithFrame:NSZeroRect]) {
        _nid = nid;
        _model = [CHLogic.shared.userDataSource nodeWithNID:nid];

        self.backgroundColor = CHTheme.shared.groupedBackgroundColor;
        
        CHFormView *formView = [CHFormView new];
        [self addSubview:(_formView = formView)];
    }
    return self;
}

- (NSString *)title {
    return self.model.name;
}

- (void)layout {
    [super layout];
    self.formView.frame = self.bounds;
}


@end
