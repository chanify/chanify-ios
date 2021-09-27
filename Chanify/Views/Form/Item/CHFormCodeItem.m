//
//  CHFormCodeItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormCodeItem.h"
#import "CHCodeFormatter.h"
#import "CHTheme.h"

@implementation CHFormCodeItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:nil]) {
        self.configuration.secondaryTextProperties.font = CHTheme.shared.codeFont;
        self.value = value ?: @"";
    }
    return self;
}

- (NSString *)textValue {
    return [CHCodeFormatter.shared formatCode:super.textValue length:kCHCodeFormatterLength];
}


@end
