//
//  CHFormItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/3.
//

#import "CHFormItem.h"
#import "CHCodeFormatter.h"
#import "CHTheme.h"

@implementation CHFormItem

+ (instancetype)itemWithName:(NSString *)name image:(UIImage *)image {
    CHFormItem *item = [CHFormItem new];
    UIListContentConfiguration *configuration = UIListContentConfiguration.valueCellConfiguration;
    configuration.text = name.localized;
    configuration.image = image;
    item->_configuration = configuration;
    item->_action = nil;
    return item;
}

+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value {
    return [self.class itemWithName:name value:value action:nil];
}

+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value action:(nullable dispatch_block_t)action {
    CHFormItem *item = [CHFormItem new];
    UIListContentConfiguration *configuration = UIListContentConfiguration.valueCellConfiguration;
    configuration.text = name.localized;
    configuration.secondaryText = value;
    item->_configuration = configuration;
    item->_action = action;
    return item;
}

+ (instancetype)itemWithName:(NSString *)name code:(NSString *)code action:(nullable dispatch_block_t)action {
    CHFormItem *item = [self.class itemWithName:name value:[[CHCodeFormatter new] stringForObjectValue:code] action:action];
    item.configuration.secondaryTextProperties.font = [UIFont fontWithName:@kCHCodeFontName size:14];
    return item;
}

+ (instancetype)itemWithName:(NSString *)name action:(dispatch_block_t)action {
    CHFormItem *item = [CHFormItem new];
    UIListContentConfiguration *configuration = UIListContentConfiguration.cellConfiguration;
    configuration.textProperties.alignment = NSTextAlignmentCenter;
    configuration.textProperties.color = CHTheme.shared.alertColor;
    configuration.text = name.localized;
    item->_configuration = configuration;
    item->_action = action;
    return item;
}


@end
