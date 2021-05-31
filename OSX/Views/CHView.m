//
//  CHView.m
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHView.h"

@implementation CHView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.wantsLayer = YES;
        self.backgroundColor = NSColor.clearColor;
    }
    return self;
}

- (void)setBackgroundColor:(CHColor *)backgroundColor {
    if (![self.backgroundColor isEqualTo:backgroundColor]) {
        _backgroundColor = backgroundColor;
        self.layer.backgroundColor = backgroundColor.CGColor;
    }
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    self.layer.backgroundColor = self.backgroundColor.CGColor;
}


@end
