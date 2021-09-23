//
//  CHListContentConfiguration.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHListContentConfiguration.h"
#import "CHListContentView.h"
#import "CHTheme.h"

@implementation CHContentTextProperties

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithFont:self.font color:self.color alignment:self.alignment];
}

- (instancetype)initWithFont:(NSFont *)font color:(NSColor *)color alignment:(NSTextAlignment)alignment {
    if (self = [super init]) {
        _font = font;
        _color = color;
        _alignment = alignment;
    }
    return self;
}

@end

@implementation CHListContentConfiguration

+ (instancetype)valueCellConfiguration {
    CHTheme *theme = CHTheme.shared;
    CHContentTextProperties *textProperties = [[CHContentTextProperties alloc] initWithFont:theme.textFont color:theme.labelColor alignment:NSTextAlignmentLeft];
    CHContentTextProperties *secondaryTextProperties = [[CHContentTextProperties alloc] initWithFont:theme.textFont color:theme.minorLabelColor alignment:NSTextAlignmentRight];
    return [[CHListContentConfiguration alloc] initWithText:nil secondaryText:nil image:nil textProperties:textProperties secondaryTextProperties:secondaryTextProperties];
}

+ (instancetype)cellConfiguration {
    CHTheme *theme = CHTheme.shared;
    CHContentTextProperties *textProperties = [[CHContentTextProperties alloc] initWithFont:theme.textFont color:theme.labelColor alignment:NSTextAlignmentLeft];
    CHContentTextProperties *secondaryTextProperties = [[CHContentTextProperties alloc] initWithFont:theme.textFont color:theme.minorLabelColor alignment:NSTextAlignmentRight];
    return [[CHListContentConfiguration alloc] initWithText:nil secondaryText:nil image:nil textProperties:textProperties secondaryTextProperties:secondaryTextProperties];
}

- (__kindof NSView<CHContentView> *)makeContentView {
    return [[CHListContentView alloc] initWithConfiguration:self];
}

- (instancetype)updatedConfigurationForState:(id<CHConfigurationState>)state {
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithText:self.text secondaryText:self.secondaryText image:self.image textProperties:[self.textProperties copyWithZone:zone] secondaryTextProperties:[self.secondaryTextProperties copyWithZone:zone]];
}

- (instancetype)initWithText:(nullable NSString *)text secondaryText:(nullable NSString *)secondaryText image:(nullable NSImage *)image textProperties:(CHContentTextProperties *)textProperties secondaryTextProperties:(CHContentTextProperties *)secondaryTextProperties {
    if (self = [super init]) {
        _text = text;
        _secondaryText = text;
        _image = image;
        _textProperties = textProperties;
        _secondaryTextProperties = secondaryTextProperties;
    }
    return self;
}


@end
