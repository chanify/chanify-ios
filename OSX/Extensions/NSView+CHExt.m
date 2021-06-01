//
//  NSView+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "NSView+CHExt.h"
#import <AppKit/AppKit.h>

@implementation NSView (CHExt)

- (void)setBackgroundColor:(NSColor *)color {
    self.layer.backgroundColor = color.CGColor;
}


@end
