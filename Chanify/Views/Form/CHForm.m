//
//  CHForm.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHForm.h"

@interface CHForm ()

@property (nonatomic, readonly, strong) NSMutableArray<CHFormSection *> *sectionList;

@end

@implementation CHForm

+ (instancetype)formWithTitle:(NSString *)title {
    return [[self.class alloc] initWithTitle:title];
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        _title = title;
        _sectionList = [NSMutableArray new];
    }
    return self;
}

- (void)setViewController:(CHFormViewController *)viewController {
    for (CHFormSection *section in self.sectionList) {
        section.viewController = viewController;
    }
}

- (NSArray<CHFormSection *> *)sections {
    return self.sectionList;
}

- (void)addFormSection:(CHFormSection *)section {
    [self.sectionList addObject:section];
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


@end
