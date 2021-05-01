//
//  CHFormButtonItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormButtonItem.h"
#import "CHTheme.h"

@interface CHFormButtonItem ()

@property (nonatomic, readonly, strong) UIListContentConfiguration *configuration;

@end

@implementation CHFormButtonItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title action:(CHFormItemActionBlock)action {
    return [[self.class alloc] initWithName:name title:title action:action];
}

- (instancetype)initWithName:(NSString *)name title:(NSString *)title action:(CHFormItemActionBlock)action {
    if (self = [super initWithName:name]) {
        UIListContentConfiguration *configuration = UIListContentConfiguration.cellConfiguration;
        configuration.textProperties.alignment = UIListContentTextAlignmentCenter;
        configuration.textProperties.color = CHTheme.shared.alertColor;
        configuration.text = title;
        _configuration = configuration;
        self.action = action;
    }
    return self;
}

- (id<UIContentConfiguration>)contentConfiguration {
    return self.configuration;
}


@end
