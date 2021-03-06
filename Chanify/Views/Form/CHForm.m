//
//  CHForm.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHForm.h"

@interface CHForm ()

@property (nonatomic, readonly, strong) NSMutableArray<CHFormSection *> *sectionList;
@property (nonatomic, readonly, strong) NSMutableArray<CHFormInputItem *> *editItems;

@end

@implementation CHForm

+ (instancetype)formWithTitle:(NSString *)title {
    return [[self.class alloc] initWithTitle:title];
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        _title = title;
        _sectionList = [NSMutableArray new];
        _editItems = [NSMutableArray new];
        _assignFirstResponderOnShow = NO;
        _errorItems = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)reloadData {
    [self.editItems removeAllObjects];
    for (CHFormSection *section in self.sectionList) {
        for (CHFormItem *item in section.allItems) {
            [item updateStatus];
            if ([item isKindOfClass:CHFormInputItem.class] && !item.isHidden) {
                [self.editItems addObject:(CHFormInputItem *)item];
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
    return self.editItems;
}

- (NSDictionary<NSString *, id> *)formValues {
    NSMutableDictionary<NSString *, id> *values = [NSMutableDictionary new];
    for (CHFormInputItem *item in self.inputItems) {
        [values setValue:item.value forKey:item.name];
    }
    return values;
}


@end
