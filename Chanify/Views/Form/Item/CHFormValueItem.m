//
//  CHFormValueItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormValueItem.h"

@interface CHFormValueItem ()

@end

@implementation CHFormValueItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    return [[self.class alloc] initWithName:name title:title value:value];
}

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title {
    return [self.class itemWithName:name title:title value:nil];
}

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name]) {
        _value = nil;
        UIListContentConfiguration *configuration = UIListContentConfiguration.valueCellConfiguration;
        configuration.text = title;
        _configuration = configuration;
        self.value = value;
    }
    return self;
}

- (id<UIContentConfiguration>)contentConfiguration {
    return self.configuration;
}

- (UITableViewCellAccessoryType)accessoryType {
    if (self.action != nil && self.configuration.textProperties.alignment == NSTextAlignmentLeft) {
        return UITableViewCellAccessoryDisclosureIndicator;
    }
    return UITableViewCellAccessoryNone;
}

- (NSString *)textValue {
    if (self.value != nil) {
        if ([self.value isKindOfClass:NSString.class]) {
            return self.value;
        }
        if ([self.value respondsToSelector:@selector(stringValue)]) {
            return [self.value stringValue];
        }
    }
    return @"";
}

- (void)setValue:(id)value {
    if (_value != value && ![_value isEqual:value]) {
        _value = value;
        self.configuration.secondaryText = self.textValue;
    }
}


@end
