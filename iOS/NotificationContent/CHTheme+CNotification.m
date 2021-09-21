//
//  CHTheme+CNotification.m
//  iOS
//
//  Created by WizJin on 2021/9/21.
//

#import "CHTheme.h"

@implementation CHTheme

+ (instancetype)shared {
    static CHTheme *theme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theme = [CHTheme new];
    });
    return theme;
}

- (instancetype)init {
    if (self = [super init]) {
        //_tintColor = [UIColor colorWithRed:10.0/255.0 green:132.0/255.0 blue:1.0 alpha:1.0];
        _tintColor = [UIColor colorNamed:@"AccentColor"];
        _labelColor = UIColor.labelColor;
        _lightLabelColor = UIColor.tertiaryLabelColor;
    }
    return self;
}


@end
