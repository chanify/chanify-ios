//
//  CHColorConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/3/8.
//

#import "CHColorConfiguration.h"

@interface CHColorContentView : UIView <UIContentView>

@property (nonatomic, copy) CHColorConfiguration *configuration;

@end

@implementation CHColorContentView

- (instancetype)initWithConfiguration:(CHColorConfiguration *)configuration {
    if (self = [super init]) {
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(CHColorConfiguration *)configuration {
    _configuration = configuration;
    NSString *color = configuration.color;
    self.backgroundColor = (color.length <= 0 ? configuration.defaultColor : [UIColor colorWithRGB:(uint32_t)color.uint64Hex]);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    self.layer.cornerRadius = MIN(size.width, size.height) * 0.5;
}

@end

@implementation CHColorConfiguration

+ (instancetype)configurationWithColor:(NSString *)color {
    return [[self.class alloc] initWithColor:color];
}

- (instancetype)initWithColor:(NSString *)color {
    if (self = [super init]) {
        _color = color;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithColor:self.color];
}

- (nonnull CHColorContentView *)makeContentView {
    return [[CHColorContentView alloc] initWithConfiguration:self];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

- (BOOL)isEqual:(CHColorConfiguration *)rhs {
    return [self.color isEqualToString:rhs.color];
}

- (NSUInteger)hash {
    return self.color.hash;
}


@end
