//
//  CHFormCodeItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormCodeItem.h"
#import "CHCodeFormatter.h"

@implementation CHFormCodeItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title code:(nullable id)code {
    return [[self.class alloc] initWithName:name title:title code:code];
}

- (instancetype)initWithName:(NSString *)name title:(NSString *)title code:(nullable id)code {
    if (self = [super initWithName:name title:title value:nil]) {
        self.configuration.secondaryTextProperties.font = [UIFont fontWithName:@kCHCodeFontName size:14];
        self.value = code;
    }
    return self;
}

- (NSString *)textValue {
    return [[CHCodeFormatter new] stringForObjectValue:super.textValue];
}


@end
