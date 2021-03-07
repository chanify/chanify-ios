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

- (id<UIContentConfiguration>)contentConfiguration {
    return nil;
}

- (void)prepareCell:(UITableViewCell *)cell {
    cell.accessoryType = self.accessoryType;
    cell.contentConfiguration = self.contentConfiguration;
}

- (UITableViewCellAccessoryType)accessoryType {
    return UITableViewCellAccessoryNone;
}

- (void)updateStatus {
    _isHidden = NO;
    if (self.hidden != nil) {
        _isHidden = [self.hidden evaluateWithObject:self];
    }
}

- (BOOL)isEqual:(CHFormItem *)rhs {
    return [self.name isEqualToString:rhs.name];
}

- (NSUInteger)hash {
    return self.name.hash;
}


@end
