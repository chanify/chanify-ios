//
//  UIColor+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/3/8.
//

#import "UIColor+CHExt.h"

@implementation UIColor (CHExt)

+ (instancetype)colorWithRGB:(uint32_t)rgb {
    const uint8_t *c = (const uint8_t *)&rgb;
    return [UIColor colorWithRed:c[2]/255.0 green:c[1]/255.0 blue:c[0]/255.0 alpha:1.0];
}


@end
