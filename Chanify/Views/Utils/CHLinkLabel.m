//
//  CHLinkLabel.m
//  Chanify
//
//  Created by WizJin on 2021/6/7.
//

#import "CHLinkLabel.h"
#import "CHTheme.h"
#import "CHMsgCellConfiguration.h"

@implementation CHLinkLabel

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
#if TARGET_OS_OSX
    return [self.text substringWithRange:self.selectedRange];
#else
    return @"";
#endif
}

#if TARGET_OS_OSX

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
        self.textContainer.lineFragmentPadding = 0;
        self.backgroundColor = NSColor.clearColor;
        self.tintColor = CHTheme.shared.tintColor;
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

- (void)resetSelectText {
    if (self.selectedRange.length <= 0) {
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self clearSelectedText];
        });
    }
}

- (void)clearSelectedText {
    self.selectedRange = NSMakeRange(NSNotFound, 0);
    if (self.window.firstResponder == self) {
        [self.window makeFirstResponder:nil];
    }
}

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    CHMsgCellContentView *view = self.contentView;
    if (view != nil) {
        [view.source activeMsgCellItem:view];
    }
}

- (void)actionCopy:(id)sender {
    [self callContentViewAction:@selector(actionCopy:) withObject:sender];
}

- (void)actionShare:(id)sender {
    [self callContentViewAction:@selector(actionShare:) withObject:sender];
}

- (void)actionDelete:(id)sender {
    [self callContentViewAction:@selector(actionDelete:) withObject:sender];
}

- (nullable CHMsgCellContentView *)contentView {
    CHView *v = self.superview;
    if (v != nil) {
        v = v.superview;
        if ([v isKindOfClass:CHMsgCellContentView.class]) {
            return (CHMsgCellContentView *)v;
        }
    }
    return nil;
}

- (void)callContentViewAction:(SEL)action withObject:(id)object {
    CHMsgCellContentView *view = self.contentView;
    if ([view respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [view performSelector:action withObject:object];
#pragma clang diagnostic pop
    }
}

#else

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.editable = NO;
        self.selectable = YES;
        self.scrollEnabled = NO;
        self.clipsToBounds = NO;
        self.backgroundColor = UIColor.clearColor;
        self.tintColor = CHTheme.shared.tintColor;
        self.dataDetectorTypes = UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
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
    if (self.selectedRange.length > 0) {
        return [super hitTest:point withEvent:event];
    }
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
    if (self.selectedRange.length <= 0) {
        self.selectedRange = NSMakeRange(0, self.text.length);
    }
}

- (void)clearSelectedText {
    if (self.selectedRange.length > 0) {
        self.selectedRange = NSMakeRange(NSNotFound, 0);
        [self resignFirstResponder];
    }
}

#endif

@end

