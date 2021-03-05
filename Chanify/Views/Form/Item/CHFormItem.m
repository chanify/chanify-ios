//
//  CHFormItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/3.
//

#import "CHFormItem.h"

@interface CHFormItem ()

@property (nonatomic, readonly, strong) UIListContentConfiguration *configuration;

@end

@implementation CHFormItem

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        _hidden = nil;
    }
    return self;
}

- (void)setConfiguration:(UIListContentConfiguration *)configuration {
    _configuration = configuration;
}

- (id<UIContentConfiguration>)contentConfiguration {
    return self.configuration;
}

- (UITableViewCellAccessoryType)accessoryType {
    return UITableViewCellAccessoryNone;
}

- (void)setIcon:(nullable UIImage *)icon {
    self.configuration.image = icon;
}

- (BOOL)isHidden {
    BOOL res = NO;
    if (self.hidden != nil) {
        return [self.hidden evaluateWithObject:self];
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
