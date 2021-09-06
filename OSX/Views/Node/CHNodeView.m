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
    }
    return self;
}

- (NSString *)title {
    return self.model.name;
}


@end
