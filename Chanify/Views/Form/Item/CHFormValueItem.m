//
//  CHFormValueItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormValueItem.h"
#import "CHPasteboard.h"
#import "CHTheme.h"

@implementation CHFormValueItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    return [[self.class alloc] initWithName:name title:title value:value];
}

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title {
    return [self.class itemWithName:name title:title value:nil];
}

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name]) {
        _value = value;
        _copiedName = nil;
        CHListContentConfiguration *configuration = CHListContentConfiguration.valueCellConfiguration;
        configuration.secondaryTextProperties.color = CHTheme.shared.minorLabelColor;
        configuration.secondaryText = self.textValue;
        configuration.text = title;
        _configuration = configuration;
    }
    return self;
}

- (id<CHContentConfiguration>)contentConfiguration {
    return self.configuration;
}

- (void)setValue:(id)value {
    if (_value != value && ![_value isEqual:value]) {
        _value = value;
        self.configuration.secondaryText = self.textValue;
    }
}

- (void)setTitleTextColor:(CHColor *)textColor {
    self.configuration.textProperties.color = textColor;
}

- (void)setIcon:(nullable CHImage *)icon {
    self.configuration.image = icon;
}

- (void)setFormatter:(CHFormValueFormatter)formatter {
    if (_formatter != formatter) {
        _formatter = formatter;
        self.configuration.secondaryText = self.textValue;
    }
}

- (CHFormViewCellAccessoryType)accessoryType {
    if (self.action != nil && self.configuration.textProperties.alignment == NSTextAlignmentLeft) {
        return CHFormViewCellAccessoryDisclosureIndicator;
    }
    return CHFormViewCellAccessoryNone;
}

- (nullable CHView *)accessoryView {
    if (self.copiedName != nil) {
        CHImageView *imageView = [[CHImageView alloc] initWithImage:[CHImage systemImageNamed:@"doc.on.doc"]];
        imageView.tintColor = CHTheme.shared.lightLabelColor;
        return imageView;
    }
    return nil;
}

- (BOOL)tryDoAction {
    BOOL res = [super tryDoAction];
    if (!res && self.copiedName != nil) {
        [CHPasteboard.shared copyWithName:self.copiedName value:self.value];
        res = YES;
    }
    return res;
}

- (__kindof NSString *)textValue {
    if (self.formatter != nil) {
        return self.formatter(self, self.value);
    }
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


@end
