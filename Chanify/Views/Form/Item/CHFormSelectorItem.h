//
//  CHFormSelectorItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormOption : NSObject

@property (nonatomic, readonly, strong) id value;
@property (nonatomic, readonly, strong) NSString *title;

+ (instancetype)formOptionWithValue:(id)value title:(NSString *)title;

@end

@interface CHFormSelectorItem : CHFormValueItem<CHFormEditableItem>

@property (nonatomic, nullable, strong) id selected;
@property (nonatomic, assign) BOOL required;
@property (nonatomic, nullable, copy) CHFormItemOnChangedBlock onChanged;

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title options:(NSArray<CHFormOption *> *)options;


@end

NS_ASSUME_NONNULL_END
