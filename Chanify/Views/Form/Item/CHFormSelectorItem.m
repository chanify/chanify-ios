//
//  CHFormSelectorItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormSelectorItem.h"
#import "CHForm.h"

@implementation CHFormOption

+ (instancetype)formOptionWithValue:(id)value title:(NSString *)title {
    CHFormOption *option = [CHFormOption new];
    option->_value = value;
    option->_title = title;
    return option;
}

@end

@interface CHFormSelectorItem ()

@property (nonatomic, readonly, strong) NSArray<CHFormOption *> *options;
@property (nonatomic, nullable, strong) CHFormOption *selectedOption;

@end

@implementation CHFormSelectorItem

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title options:(NSArray<CHFormOption *> *)options {
    return [[self.class alloc] initWithName:name title:title options:options];
}

- (instancetype)initWithName:(NSString *)name title:(NSString *)title options:(NSArray<CHFormOption *> *)options {
    if (self = [super initWithName:name title:title value:nil]) {
        _required = NO;
        _selected = nil;
        _selectedOption = nil;
        _options = options;
        self.action = ^(CHFormSelectorItem *item) {
            [item doSelectItem];
        };
    }
    return self;
}


- (CHFormViewCellAccessoryType)accessoryType {
    return CHFormViewCellAccessoryDisclosureIndicator;
}

- (void)setSelected:(id)selected {
    if (_selected != selected) {
        _selected = selected;
        for (CHFormOption *option in self.options) {
            if ([option.value isEqual:selected]) {
                _selectedOption = option;
                super.value = option.value;
                break;
            }
        }
    }
}

- (__kindof NSString *)textValue {
    NSString *res = nil;
    if (self.selectedOption != nil) {
        res = self.selectedOption.title;
    }
    return res ?: @"";
}

- (void)doSelectItem {
    if (self.options.count > 0) {
        CHAlertController *alert = [CHAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        @weakify(self);
        for (CHFormOption *option in self.options) {
            UIAlertAction *act = [UIAlertAction actionWithTitle:option.title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                dispatch_main_async(^{
                    @strongify(self);
                    [self itemSelected:option];
                });
            }];
            [alert addAction:act];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".localized style:UIAlertActionStyleCancel handler:nil]];
        [self.section.form.viewDelegate showActionSheet:alert item:self animated:YES];
    }
}

- (void)itemSelected:(CHFormOption *)option {
    if (self.selected != option.value) {
        id oldValue = self.selected;
        self.selected = option.value;
        self.selectedOption = option;
        [self.section.form notifyItemValueHasChanged:self oldValue:oldValue newValue:option.value];
        [self setSelected:option.value];
        [self.section.form.viewDelegate reloadItem:self];
    }
}


@end
