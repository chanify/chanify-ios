//
//  CHPasteboard.m
//  Chanify
//
//  Created by WizJin on 2021/4/1.
//

#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHUI.h"

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
    [self setStringValue:value];
    [CHRouter.shared makeToast:[NSString stringWithFormat:@"%@ copied".localized, name]];
}

#if TARGET_OS_OSX
- (nullable NSString *)stringValue {
    return [NSPasteboard.generalPasteboard stringForType:NSPasteboardTypeString];
}

- (void)setStringValue:(nullable NSString *)value {
    NSPasteboard *pasteBoard = NSPasteboard.generalPasteboard;
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pasteBoard setString:(value ?: @"") forType:NSPasteboardTypeString];
}

#else
- (nullable NSString *)stringValue {
    return UIPasteboard.generalPasteboard.string;
}

- (void)setStringValue:(nullable NSString *)value {
    UIPasteboard.generalPasteboard.string = value ?: @"";
}
#endif

@end
