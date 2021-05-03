//
//  NSImage+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/5/3.
//

#import "NSImage+CHExt.h"

@implementation NSImage (CHExt)

+ (instancetype)systemImageNamed:(NSString *)name {
    return [NSImage imageWithSystemSymbolName:name accessibilityDescription:name];
}

+ (nullable instancetype)imageWithData:(NSData *)data {
    if (data.length > 0) {
        return [[NSImage alloc] initWithData:data];
    }
    return nil;
}


@end
