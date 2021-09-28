//
//  NSButton+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSButton+CHExt.h"

@implementation NSButton (CHExt)

+ (instancetype)systemButtonWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action {
    return [NSButton buttonWithImage:image target:target action:action];
}

+ (instancetype)button {
    return [NSButton new];
}

- (void)setTagID:(NSInteger)tagID {
    self.tag = tagID;
}

- (NSInteger)tagID {
    return self.tag;
}

- (nullable NSView *)viewWithTagID:(NSInteger)tagID {
    return [self viewWithTag:tagID];
}

- (void)setTitleFont:(NSFont *)font {
    // TODO: set font
}

- (void)setTitleTintColor:(NSColor *)color {
    
}

- (void)setTitleSelectColor:(NSColor *)color {
    
}

- (void)setNormalTitle:(NSString *)normalTitle {
    [self setTitle:normalTitle];
}

- (void)addTarget:(nullable id)target action:(SEL)action {
    self.target = target;
    self.action = action;
}


@end
