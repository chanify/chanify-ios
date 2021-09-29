//
//  CHProgressView.m
//  OSX
//
//  Created by WizJin on 2021/9/30.
//

#import "CHProgressView.h"
#import "CHUI.h"

@interface CHProgressView ()

@end

@implementation CHProgressView

- (instancetype)initWithProgressViewStyle:(NSProgressIndicatorStyle)style {
    if (self = [super init]) {
        _progress = 0;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    if (_progress != progress) {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    [self.trackTintColor setFill];
    NSRect bounds = self.bounds;
    CGContextFillRect(context, dirtyRect);
    bounds.size.width *= MAX(MIN(self.progress, 1), 0);
    [self.tintColor setFill];
    CGContextFillRect(context, bounds);
}


@end
