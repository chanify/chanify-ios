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
        self.cell.scrollable = NO;
        self.drawsBackground = NO;
        self.editable = NO;
        self.bezeled = NO;
        self.bordered = NO;
    }
    return self;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    self.alignment = textAlignment;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    self.maximumNumberOfLines = numberOfLines;
}

- (void)setText:(nullable NSString *)text {
    self.stringValue = text ?: @"";
}

- (NSString *)text {
    return self.stringValue;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.attributedStringValue = attributedText;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    NSSize size = [self.cell cellSizeForBounds:bounds];
    if (size.height != bounds.size.height) {
        bounds.origin.y = (bounds.size.height - size.height)/2;
    }
    // Fix: NSCell margin
    bounds.origin.x -= 2;
    bounds.size.width += 4;
    [self.cell drawWithFrame:bounds inView:self];
}


@end
