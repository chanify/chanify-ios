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
    self.tintColor = CHTheme.shared.minorLabelColor;
    self.image = configuration.icon;
    self.backgroundColor = UIColor.clearColor;
}

@end

@implementation CHIconConfiguration

+ (instancetype)configurationWithIcon:(NSString *)icon {
    return [[self.class alloc] initWithIcon:icon];
}

- (instancetype)initWithIcon:(NSString *)icon {
    if (self = [super init]) {
        _icon = icon;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithIcon:self.icon];
}

- (nonnull CHIconContentView *)makeContentView {
    CHIconContentView *iconView = [[CHIconContentView alloc] initWithConfiguration:self];
    iconView.backgroundColor = UIColor.clearColor;
    return iconView;
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
