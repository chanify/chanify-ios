//
//  CHCodeFormatter.m
//  Chanify
//
//  Created by WizJin on 2021/2/21.
//

#import "CHCodeFormatter.h"

@implementation CHCodeFormatter

+ (instancetype)shared {
    static CHCodeFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [CHCodeFormatter new];
    });
    return formatter;
}

- (nullable NSString *)formatCode:(NSString *)val length:(NSUInteger)length {
    length = MAX(length, 10);
    NSUInteger len = val.length;
    if (len <= length) {
        return val;
    }
    return [NSString stringWithFormat:@"%@…%@", [val substringToIndex:length-5], [val substringFromIndex:len-4]];
}


@end
