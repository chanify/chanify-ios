//
//  CHFormSection.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormSection.h"

@interface CHFormSection ()

@property (nonatomic, readonly, strong) NSMutableArray<CHFormItem *> *itemList;

@end

@implementation CHFormSection

+ (instancetype)sectionWithTitle:(NSString *)title {
    return [[self.class alloc] initWithTitle:title];
}

+ (instancetype)section {
    return [self.class sectionWithTitle:@""];
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        _title = (title ?: @"");
        _itemList = [NSMutableArray new];
    }
    return self;
}

- (NSArray<CHFormItem *> *)items {
    NSMutableArray<CHFormItem *> *rows = [NSMutableArray arrayWithCapacity:self.itemList.count];
    for (CHFormItem *item in self.itemList) {
        if (!item.isHidden) {
            [rows addObject:item];
        }
    }
    return rows;
}

- (NSArray<CHFormItem *> *)allItems {
    return self.itemList;
}

- (void)addFormItem:(CHFormItem *)item {
    [self.itemList addObject:item];
    item.section = self;
}


@end
