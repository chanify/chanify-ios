//
//  CHFormInputItem+OSX.m
//  Chanify
//
//  Created by WizJin on 2021/9/18.
//

#import "CHFormInputItem.h"
#import "CHTheme.h"
#import "CHForm.h"

@interface CHFormInputItem () <NSTextFieldDelegate>

@end

@implementation CHFormInputItem

- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value {
    if (self = [super initWithName:name title:title value:value ?: @""]) {
        _required = NO;
        _inputType = CHFormInputTypeText;
        self.action = ^(CHFormInputItem *item) {
            [item startEditing];
        };
    }
    return self;
}

- (CHFormViewCellAccessoryType)accessoryType {
    return CHFormViewCellAccessoryNone;
}

- (void)startEditing {
    NSTextField *textField = self.editView;
    if (textField != nil) {
        textField.hidden = NO;
        textField.stringValue = self.value;
        CHFormViewCell *cell = [self.section.form.viewDelegate cellForItem:self];
        if (cell != nil) {
            self.configuration.secondaryTextProperties.color = CHColor.clearColor;
            cell.contentConfiguration = self.contentConfiguration;
            [cell setNeedsUpdateConfiguration];
        }
    }
    [textField becomeFirstResponder];
}

- (NSTextField *)editView {
    CHListContentView *contentView = (CHListContentView *)[[self.section.form.viewDelegate cellForItem:self] contentView];
    NSTextField *textField = [contentView viewWithTagID:kCHFormTextFieldTag];
    if (textField == nil) {
        CHTheme *theme = CHTheme.shared;
        textField = [NSTextField new];
        [contentView addSubview:textField];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addConstraints:@[
            [textField.centerYAnchor constraintEqualToAnchor:contentView.centerYAnchor],
            [textField.rightAnchor constraintEqualToAnchor:contentView.secondaryTextLayoutGuide.rightAnchor constant:-10],
            [textField.leftAnchor constraintEqualToAnchor:contentView.textLayoutGuide.leftAnchor constant:70],
        ]];
        textField.tagID = kCHFormTextFieldTag;
        textField.cell.scrollable = YES;
        textField.cell.usesSingleLineMode = YES;
        textField.cell.focusRingType = NSFocusRingTypeNone;
        textField.textColor = theme.labelColor;
        textField.font = theme.textFont;
        textField.maximumNumberOfLines = 1;
        textField.drawsBackground = NO;
        textField.bezeled = NO;
        textField.bordered = NO;
        textField.highlighted = NO;
        textField.editable = YES;
        textField.delegate = self;
        textField.backgroundColor = NSColor.redColor;
//        switch (self.inputType) {
//            case CHFormInputTypeText:
//                textField.autocorrectionType = UITextAutocorrectionTypeDefault;
//                textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
//                break;
//            case CHFormInputTypeAccount:
//                textField.keyboardType = UIKeyboardTypeASCIICapable;
//                textField.autocorrectionType = UITextAutocorrectionTypeNo;
//                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//                break;
//        }
    }
    return textField;
}

#pragma mark - NSTextFieldDelegate
- (void)controlTextDidEndEditing:(NSNotification *)info {
    id<CHFormViewDelegate> viewDelegate = self.section.form.viewDelegate;
    CHListContentView *contentView = (CHListContentView *)[[viewDelegate cellForItem:self] contentView];
    NSTextField *textField = [contentView viewWithTagID:kCHFormTextFieldTag];
    if (textField != nil) {
        textField.hidden = YES;
        self.value =  textField.stringValue;
        [textField resignFirstResponder];
        CHFormViewCell *cell = [viewDelegate cellForItem:self];
        if (cell != nil) {
            self.configuration.secondaryTextProperties.color = CHTheme.shared.minorLabelColor;
            cell.contentConfiguration = self.contentConfiguration;
            [cell setNeedsUpdateConfiguration];
        }
    }
}


@end
