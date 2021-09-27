//
//  CHFormItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/3.
//

#import "CHFormItem.h"

@interface CHFormItem ()

@property (nonatomic, readonly, assign) BOOL isHidden;

@end

@implementation CHFormItem

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        _hidden = nil;
        _isHidden = NO;
    }
    return self;
}

- (id<CHContentConfiguration>)contentConfiguration {
    return nil;
}

- (void)prepareCell:(CHFormViewCell *)cell {
    for (CHView *view in cell.contentView.subviews) {
        if (view.tagID >= kCHFormFirstViewTag) {
            [view removeFromSuperview];
        }
    }

    cell.accessoryType = self.accessoryType;
    cell.contentConfiguration = self.contentConfiguration;
    CHView *accessoryView = nil;
    if (cell.accessoryType == CHFormViewCellAccessoryNone) {
        accessoryView = self.accessoryView;
    }
    if (cell.accessoryView != accessoryView) {
        cell.accessoryView = accessoryView;
    }
}

- (CHFormViewCellAccessoryType)accessoryType {
    return CHFormViewCellAccessoryNone;
}

- (nullable CHView *)accessoryView {
    return nil;
}

- (void)updateStatus {
    _isHidden = NO;
    if (self.hidden != nil) {
        _isHidden = [self.hidden evaluateWithObject:self];
    }
}

- (BOOL)tryDoAction {
    BOOL res = NO;
    if (self.action != nil) {
        self.action(self);
        res = YES;
    }
    return res;
}

- (BOOL)isEqual:(CHFormItem *)rhs {
    return [self.name isEqualToString:rhs.name];
}

- (NSUInteger)hash {
    return self.name.hash;
}


@end
