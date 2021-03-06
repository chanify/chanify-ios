//
//  CHFormSection.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormCodeItem.h"
#import "CHFormButtonItem.h"
#import "CHFormInputItem.h"
#import "CHFormSelectorItem.h"

NS_ASSUME_NONNULL_BEGIN

@class CHForm;

@interface CHFormSection : NSObject

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, weak) CHForm *form;

+ (instancetype)sectionWithTitle:(NSString *)title;
+ (instancetype)section;
- (NSArray<CHFormItem *> *)items;
- (NSArray<CHFormItem *> *)allItems;
- (void)addFormItem:(CHFormItem *)item;


@end

NS_ASSUME_NONNULL_END
