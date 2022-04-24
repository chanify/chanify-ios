//
//  CHJSBuffer.m
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import "CHJSBuffer.h"

@implementation CHJSBuffer

+ (instancetype)shared {
    static CHJSBuffer *buffer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        buffer = [CHJSBuffer new];
    });
    return buffer;
}

- (NSInteger)byteLength:(id)data {
    if (data != nil) {
        if ([data isKindOfClass:NSData.class]) {
            return [(NSData *)data length];
        } else if ([data isKindOfClass:NSString.class]) {
            return [(NSString *)data length];
        } else if ([data isKindOfClass:NSArray.class]) {
            return [(NSArray *)data count];
        }
    }
    return 0;
}


@end
