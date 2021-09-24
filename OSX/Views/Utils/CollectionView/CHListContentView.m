//
//  CHListContentView.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHListContentView.h"
#import <Masonry/Masonry.h>
#import "CHListContentConfiguration.h"
#import "CHTheme.h"

@interface CHListContentView ()

@property (nonatomic, readonly, strong) CHImageView *iconView;
@property (nonatomic, readonly, strong) CHLabel *textLabel;
@property (nonatomic, readonly, strong) CHLabel *secondaryTexLabel;

@end

@implementation CHListContentView

- (instancetype)initWithConfiguration:(CHListContentConfiguration *)configuration {
    if (self = [super init]) {
        CHTheme *theme = CHTheme.shared;
        
        CHImageView *iconView = [CHImageView new];
        [self addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(CHListContentViewMargin);
            make.top.bottom.equalTo(self);
            make.width.mas_equalTo(20);
        }];
        iconView.tintColor = theme.tintColor;
        iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
        
        CHLabel *textLabel = [CHLabel new];
        [self addSubview:(_textLabel = textLabel)];
        [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(CHListContentViewMargin);
            make.centerY.equalTo(self);
        }];

        CHLabel *secondaryTexLabel = [CHLabel new];
        [self addSubview:(_secondaryTexLabel = secondaryTexLabel)];
        [secondaryTexLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(textLabel.mas_right).offset(4);
            make.centerY.equalTo(textLabel);
            make.right.equalTo(self).offset(-CHListContentViewMargin);
        }];
        
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(id<CHContentConfiguration>)configuration {
    if (_configuration != configuration) {
        _configuration = configuration;
        if ([configuration isKindOfClass:CHListContentConfiguration.class]) {
            CHListContentConfiguration *listConfiguration = (CHListContentConfiguration *)configuration;
            
            CHImage *image = listConfiguration.image;
            self.iconView.image = image;
            self.iconView.hidden = (image == nil);
            
            [self.textLabel mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(CHListContentViewMargin + (image == nil ? 0 : 36));
            }];

            self.textLabel.text = listConfiguration.text ?: @"";
            self.textLabel.textColor = listConfiguration.textProperties.color;
            self.textLabel.font = listConfiguration.textProperties.font;
            self.textLabel.alignment = listConfiguration.textProperties.alignment;
            
            self.secondaryTexLabel.text = listConfiguration.secondaryText ?: @"";
            self.secondaryTexLabel.textColor = listConfiguration.secondaryTextProperties.color;
            self.secondaryTexLabel.font = listConfiguration.secondaryTextProperties.font;
            self.secondaryTexLabel.alignment = listConfiguration.secondaryTextProperties.alignment;
        }
    }
}

- (NSLayoutGuide *)textLayoutGuide {
    return self.textLabel.safeAreaLayoutGuide;
}

- (NSLayoutGuide *)secondaryTextLayoutGuide {
    return self.secondaryTexLabel.safeAreaLayoutGuide;
}


@end
