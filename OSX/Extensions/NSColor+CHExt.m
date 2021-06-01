//
//  NSColor+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "NSColor+CHExt.h"

@implementation NSColor (CHExt)

+ (instancetype)colorWithRGB:(uint32_t)rgb {
    const uint8_t *c = (const uint8_t *)&rgb;
    return [NSColor colorWithRed:c[2]/255.0 green:c[1]/255.0 blue:c[0]/255.0 alpha:1.0];
}


@end
