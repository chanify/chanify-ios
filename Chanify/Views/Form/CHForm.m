//
//  CHForm.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHForm.h"

@interface CHForm ()

@property (nonatomic, readonly, strong) NSMutableArray<CHFormSection *> *sectionList;
@property (nonatomic, readonly, strong) NSMutableArray<CHFormInputItem *> *inputItemList;
@property (nonatomic, readonly, strong) NSHashTable<id<CHFormEditableItem>> *editItems;

@end

@implementation CHForm

+ (instancetype)formWithTitle:(NSString *)title {
    return [[self.class alloc] initWithTitle:title];
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        _title = title;
        _sectionList = [NSMutableArray new];
        _inputItemList = [NSMutableArray new];
        _editItems = [NSHashTable weakObjectsHashTable];
        _assignFirstResponderOnShow = NO;
        _errorItems = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)reloadData {
    [self.errorItems removeAllObjects];
    [self.editItems removeAllObjects];
    [self.inputItemList removeAllObjects];
    for (CHFormSection *section in self.sectionList) {
        for (CHFormItem *item in section.allItems) {
            [item updateStatus];
            if ([item isKindOfClass:CHFormInputItem.class] && !item.isHidden) {
                [self.inputItemList addObject:(CHFormInputItem *)item];
            }
            if ([item conformsToProtocol:@protocol(CHFormEditableItem)]) {
                id<CHFormEditableItem> itm = (id<CHFormEditableItem>)item;
                [self.editItems addObject:itm];
            }
        }
    }
}

- (NSArray<CHFormSection *> *)sections {
    return self.sectionList;
}

- (void)addFormSection:(CHFormSection *)section {
    [self.sectionList addObject:section];
    section.form = self;
}

- (nullable CHFormItem *)formItemWithName:(NSString *)name {
    for (CHFormSection *section in self.sectionList) {
        for (CHFormItem *item in section.allItems) {
            if ([item.name isEqualToString:name]) {
                return item;
            }
        }
    }
    return nil;
}

- (NSArray<CHFormInputItem *> *)inputItems {
    return self.inputItemList;
}

- (NSDictionary<NSString *, id> *)formValues {
    NSMutableDictionary<NSString *, id> *values = [NSMutableDictionary new];
    for (id<CHFormEditableItem> item in self.editItems) {
        [values setValue:item.value forKey:item.name];
    }
    return values;
}

- (void)notifyItemValueHasChanged:(id<CHFormEditableItem>)item oldValue:(id)oldValue newValue:(id)newValue {
    [self validateItemValue:item];
    if (item.onChanged != nil) {
        item.onChanged(item, oldValue, newValue);
    }
    if ([self.delegate respondsToSelector:@selector(formItemValueHasChanged:oldValue:newValue:)]) {
        [self.delegate formItemValueHasChanged:item oldValue:oldValue newValue:newValue];
    }
}

#pragma mark - Private Methods
- (void)validateItemValue:(id<CHFormEditableItem>)item {
    if (item.required) {
        id value = item.value;
        if (value == nil || [value length] <= 0) {
            [self.errorItems addObject:self];
            return;
        }
    }
    [self.errorItems removeObject:self];
}


@end
