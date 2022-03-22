//
//  CHLinkLabel.m
//  Chanify
//
//  Created by WizJin on 2021/6/7.
//

#import "CHLinkLabel.h"

@implementation CHLinkLabel

#if TARGET_OS_OSX

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
        self.textContainer.lineFragmentPadding = 0;
        self.backgroundColor = NSColor.clearColor;
        self.automaticLinkDetectionEnabled = YES;
        self.selectable = NO;
        self.editable = NO;
    }
    return self;
}

- (void)setText:(NSString *)text {
    self.string = text;
    [self setEditable:YES];
    [self checkTextInDocument:nil];
    [self setEditable:NO];
}

- (NSString *)text {
    return self.string;
}

- (BOOL)resignFirstResponder {
    self.selectedRange = NSMakeRange(0, 0);
    return [super resignFirstResponder];
}

- (void)resetSelectText {
    if (self.selectedRange.length <= 0) {
        [self selectAll:nil];
    }
}

#else

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.editable = NO;
        self.selectable = YES;
        self.backgroundColor = UIColor.clearColor;
        self.dataDetectorTypes = UIDataDetectorTypeAll;
        self.textContainerInset = UIEdgeInsetsZero;
        self.textContainer.lineFragmentPadding = 0;
        self.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        self.linkTextAttributes = @{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        };
    }
    return self;
}

- (nullable CHColor *)linkColor {
    return [self.linkTextAttributes objectForKey:NSForegroundColorAttributeName];
}

- (void)setLinkColor:(CHColor *)linkColor {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:self.linkTextAttributes];
    [attrs setObject:linkColor forKey:NSForegroundColorAttributeName];
    self.linkTextAttributes = attrs;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}

- (NSInteger)characterIndexForInsertionAtPoint:(CGPoint)point {
    NSInteger offset = -1;
    UITextPosition *pos = [self closestPositionToPoint:point];
    if (pos != nil) {
        offset = [self offsetFromPosition:self.beginningOfDocument toPosition:pos];
    }
    return offset;
}

- (void)resetSelectText {
}

#endif

- (NSString *)linkForPoint:(CGPoint)point {
    NSInteger index = [self characterIndexForInsertionAtPoint:point];
    if (index >= 0 && index < self.text.length) {
        NSDictionary *info = [self.textStorage attributesAtIndex:index effectiveRange:nil];
        if (info != nil) {
            NSURL *url = [info valueForKey:NSLinkAttributeName];
            if (url != nil) {
                return url.absoluteString;
            }
        }
    }
    return @"";
}

- (NSString *)selectedText {
    return [self.text substringWithRange:self.selectedRange];
}


@end

