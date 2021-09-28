//
//  CHFormInputItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/6.
//

#import "CHFormInputItem.h"
#import "CHForm.h"
#import "CHTheme.h"

@interface CHFormInputItem () <UITextFieldDelegate>

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
    self.editView.alpha = 1;
    [self.section.form.viewDelegate itemBecomeFirstResponder:self];
}

- (UITextField *)editView {
    CHListContentView *contentView = (CHListContentView *)[[self.section.form.viewDelegate cellForItem:self] contentView];
    UITextField *textField = [contentView viewWithTagID:kCHFormTextFieldTag];
    if (textField == nil) {
        textField = [UITextField new];
        [contentView addSubview:textField];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:contentView.topAnchor],
            [textField.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
            [textField.rightAnchor constraintEqualToAnchor:contentView.secondaryTextLayoutGuide.rightAnchor],
            [textField.leftAnchor constraintEqualToAnchor:contentView.textLayoutGuide.rightAnchor constant:10],
        ]];
        [textField addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.tagID = kCHFormTextFieldTag;
        textField.delegate = self;
        switch (self.inputType) {
            case CHFormInputTypeText:
                textField.autocorrectionType = UITextAutocorrectionTypeDefault;
                textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
                break;
            case CHFormInputTypeAccount:
                textField.keyboardType = UIKeyboardTypeASCIICapable;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                break;
        }
    }
    return textField;
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    id<CHFormViewDelegate> viewDelegate = self.section.form.viewDelegate;
    textField.text = self.value;
    textField.inputAccessoryView = [viewDelegate itemAccessoryView:self];
    textField.returnKeyType = ([viewDelegate itemIsLastInput:self] ? UIReturnKeyDone : UIReturnKeyNext);
    UITableViewCell *cell = [viewDelegate cellForItem:self];
    if (cell != nil) {
        self.configuration.secondaryTextProperties.color = UIColor.clearColor;
        cell.contentConfiguration = self.contentConfiguration;
        [cell setNeedsUpdateConfiguration];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDidChanged:textField];
    textField.alpha = 0;
    CHFormViewCell *cell = [self.section.form.viewDelegate cellForItem:self];
    if (cell != nil) {
        self.configuration.secondaryTextProperties.color = CHTheme.shared.minorLabelColor;
        cell.contentConfiguration = self.contentConfiguration;
        [cell setNeedsUpdateConfiguration];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self.section.form.viewDelegate itemShouldInputReturn:self];
}

- (void)textFieldDidChanged:(UITextField *)textField {
    if (![textField.text isEqualToString:self.value]) {
        id old = self.value;
        self.value = textField.text;
        [self.section.form notifyItemValueHasChanged:self oldValue:old newValue:textField.text];
    }
}


@end
