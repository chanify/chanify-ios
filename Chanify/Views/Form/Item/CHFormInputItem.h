//
//  CHFormInputItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/6.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHFormInputType) {
    CHFormInputTypeText = 0,
    CHFormInputTypeAccount = 1,
};

@interface CHFormInputItem : CHFormValueItem<CHFormEditableItem>

@property (nonatomic, assign) BOOL required;
@property (nonatomic, nullable, copy) CHFormItemOnChangedBlock onChanged;
@property (nonatomic, assign) CHFormInputType inputType;

- (void)startEditing;
- (__kindof CHView *)editView;


@end

NS_ASSUME_NONNULL_END
