//
//  CHLabel.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHLabel.h"

@implementation CHLabel

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.cell.truncatesLastVisibleLine = YES;
        self.backgroundColor = NSColor.clearColor;
        self.editable = NO;
        self.bezeled = NO;
    }
    return self;
}

- (void)setText:(nullable NSString *)text {
    self.stringValue = text ?: @"";
}


@end
