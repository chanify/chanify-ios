//
//  CHFormSection.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormCodeItem.h"
#import "CHFormIconItem.h"
#import "CHFormDateItem.h"
#import "CHFormButtonItem.h"
#import "CHFormSwitchItem.h"
#import "CHFormInputItem.h"
#import "CHFormSelectorItem.h"

NS_ASSUME_NONNULL_BEGIN

@class CHForm;

@interface CHFormSection : NSObject

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, nullable, strong) NSPredicate *hidden;
@property (nonatomic, weak) CHForm *form;

+ (instancetype)sectionWithTitle:(NSString *)title;
+ (instancetype)section;
- (void)updateStatus;
- (NSArray<CHFormItem *> *)items;
- (NSArray<CHFormItem *> *)allItems;
- (nullable __kindof CHFormItem *)itemWithName:(NSString *)name;
- (void)addFormItem:(CHFormItem *)item;
- (BOOL)isHidden;


@end

NS_ASSUME_NONNULL_END
