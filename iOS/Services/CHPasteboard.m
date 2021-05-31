//
//  CHPasteboard.m
//  Chanify
//
//  Created by WizJin on 2021/4/1.
//

#import "CHPasteboard.h"
#import "CHRouter+iOS.h"

@implementation CHPasteboard

+ (instancetype)shared {
    static CHPasteboard *pasteboard;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pasteboard = [CHPasteboard new];
    });
    return pasteboard;
}

- (void)copyWithName:(NSString *)name value:(nullable NSString *)value {
    UIPasteboard.generalPasteboard.string = value ?: @"";
    [CHRouter.shared makeToast:[NSString stringWithFormat:@"%@ copied".localized, name]];
}


@end
