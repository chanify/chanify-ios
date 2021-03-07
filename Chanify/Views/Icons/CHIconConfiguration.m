//
//  CHIconConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHIconConfiguration.h"
#import <Masonry/Masonry.h>
#import "CHIconView.h"
#import "CHTheme.h"

@interface CHIconContentView : CHIconView <UIContentView>

@property (nonatomic, copy) CHIconConfiguration *configuration;

@end

@implementation CHIconContentView

- (instancetype)initWithConfiguration:(CHIconConfiguration *)configuration {
    if (self = [super init]) {
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(CHIconConfiguration *)configuration {
    _configuration = configuration;
    NSString *name = configuration.icon.lowercaseString;
    name = [name stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    self.image = name;
    self.tintColor = configuration.tintColor;
}

@end

@implementation CHIconConfiguration

+ (instancetype)configurationWithIcon:(NSString *)icon tintColor:(UIColor *)tintColor {
    return [[self.class alloc] initWithIcon:icon tintColor:tintColor];
}

- (instancetype)initWithIcon:(NSString *)icon tintColor:(UIColor *)tintColor {
    if (self = [super init]) {
        _icon = icon;
        _tintColor = tintColor;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithIcon:self.icon tintColor:self.tintColor];
}

- (nonnull CHIconContentView *)makeContentView {
    return [[CHIconContentView alloc] initWithConfiguration:self];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

- (BOOL)isEqual:(CHIconConfiguration *)rhs {
    return [self.icon isEqualToString:rhs.icon];
}

- (NSUInteger)hash {
    return self.icon.hash;
}


@end
