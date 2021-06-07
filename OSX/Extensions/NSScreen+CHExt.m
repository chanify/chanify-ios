//
//  NSScreen+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "NSScreen+CHExt.h"

@implementation NSScreen (CHExt)

- (CGFloat)scale {
    return self.backingScaleFactor;
}

@end
