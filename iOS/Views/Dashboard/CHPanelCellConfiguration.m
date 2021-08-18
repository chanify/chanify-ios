//
//  CHPanelCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/6/21.
//

#import "CHPanelCellConfiguration.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHPanelCellContentView : UIView<UIContentView>

@property (nonatomic, copy) CHPanelCellConfiguration *configuration;
@property (nonatomic, readonly, strong) UILabel *titleLabel;

- (instancetype)initWithConfiguration:(CHPanelCellConfiguration *)configuration;

@end

@implementation CHPanelCellContentView

- (instancetype)initWithConfiguration:(CHPanelCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        self.configuration = configuration;
        
        CHTheme *theme = CHTheme.shared;

        UILabel *titleLabel = [UILabel new];
        [self addSubview:(_titleLabel = titleLabel)];
        titleLabel.textColor = theme.labelColor;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = theme.textFont;
        titleLabel.numberOfLines = 1;
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

- (void)setConfiguration:(CHPanelCellConfiguration *)configuration {
    if (![self.configuration isEqual:configuration]) {
        _configuration = configuration;
    }
    self.titleLabel.text = self.configuration.code ?: @"";
}

@end

@implementation CHPanelCellConfiguration

+ (instancetype)cellConfiguration:(NSString *)code {
    return [[self.class alloc] initWithCode:code];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithCode:self.code];
}

- (instancetype)initWithCode:(NSString *)code {
    if (self = [super init]) {
        _code = code;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHPanelCellContentView alloc] initWithConfiguration:self];
}

- (instancetype)updatedConfigurationForState:(id<UIConfigurationState>)state {
    return self;
}

- (BOOL)isEqual:(CHPanelCellConfiguration *)rhs {
    return [self.code isEqualToString:rhs.code];
}

- (NSUInteger)hash {
    return self.code.hash;
}


@end
