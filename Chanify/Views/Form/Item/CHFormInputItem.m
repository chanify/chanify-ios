//
//  CHFormInputItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/6.
//

#import "CHFormInputItem.h"
#import "CHFormViewController.h"
#import "CHTheme.h"

#define kTextFieldTag   1000

@interface CHFormInputItem () <UITextFieldDelegate>

@end

@implementation CHFormInputItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title {
    return [[self.class alloc] initWithName:name title:title value:nil];
}

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

- (UITableViewCellAccessoryType)accessoryType {
    return UITableViewCellAccessoryNone;
}

- (void)startEditing {
    self.editView.alpha = 1;
    [self.section.form.viewController itemBecomeFirstResponder:self];
}

- (void)setValue:(id)value {
    [super setValue:value];
    [self validateInputValue];
}

- (void)setRequired:(BOOL)required {
    _required = required;
    [self validateInputValue];
}

- (UITextField *)editView {
    UIListContentView *contentView = (UIListContentView *)[[self.section.form.viewController cellForItem:self] contentView];
    UITextField *textField = [contentView viewWithTag:kTextFieldTag];
    if (textField == nil) {
        textField = [UITextField new];
        [contentView addSubview:textField];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:contentView.topAnchor],
            [textField.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
            [textField.rightAnchor constraintEqualToAnchor:contentView.rightAnchor constant:-10],
            [textField.leftAnchor constraintEqualToAnchor:contentView.textLayoutGuide.rightAnchor constant:10],
        ]];
        [textField addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.tag = kTextFieldTag;
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
    CHFormViewController *viewController = self.section.form.viewController;
    textField.text = self.value;
    textField.inputAccessoryView = [viewController itemAccessoryView:self];
    textField.returnKeyType = ([viewController itemIsLastInput:self] ? UIReturnKeyDone : UIReturnKeyNext);
    UITableViewCell *cell = [self.section.form.viewController cellForItem:self];
    if (cell != nil) {
        self.configuration.secondaryTextProperties.color = UIColor.clearColor;
        cell.contentConfiguration = self.contentConfiguration;
        [cell setNeedsUpdateConfiguration];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDidChanged:textField];
    textField.alpha = 0;
    UITableViewCell *cell = [self.section.form.viewController cellForItem:self];
    if (cell != nil) {
        self.configuration.secondaryTextProperties.color = CHTheme.shared.minorLabelColor;
        cell.contentConfiguration = self.contentConfiguration;
        [cell setNeedsUpdateConfiguration];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self.section.form.viewController itemShouldInputReturn:self];
}

- (void)textFieldDidChanged:(UITextField *)textField {
    if (![textField.text isEqualToString:self.value]) {
        id old = self.value;
        self.value = textField.text;
        if ([self.section.form.delegate respondsToSelector:@selector(formItemValueHasChanged:oldValue:newValue:)]) {
            [self.section.form.delegate formItemValueHasChanged:self oldValue:old newValue:self.value];
        }
    }
}

#pragma mark - Private Methods
- (void)validateInputValue {
    if (self.required && (self.value == nil || ((NSString *)self.value).length <= 0)) {
        [self.section.form.errorItems addObject:self];
    } else {
        [self.section.form.errorItems removeObject:self];
    }
}


@end
