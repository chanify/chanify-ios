//
//  CHCodeFormatter.m
//  Chanify
//
//  Created by WizJin on 2021/2/21.
//

#import "CHCodeFormatter.h"

#define kCHCodeFormatterLength  24

@implementation CHCodeFormatter

+ (instancetype)shared {
    static CHCodeFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [CHCodeFormatter new];
    });
    return formatter;
}

- (nullable NSString *)stringForObjectValue:(NSString *)val {
    NSUInteger len = val.length;
    if (len <= kCHCodeFormatterLength) {
        return val;
    }
    return [NSString stringWithFormat:@"%@…%@", [val substringToIndex:kCHCodeFormatterLength-5], [val substringFromIndex:len-4]];
}


@end
