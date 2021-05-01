//
//  CHFormSwitchItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/17.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormSwitchItem : CHFormValueItem<CHFormEditableItem>

@property (nonatomic, assign) BOOL required;
@property (nonatomic, assign) BOOL enbaled;
@property (nonatomic, nullable, copy) CHFormItemOnChangedBlock onChanged;


@end

NS_ASSUME_NONNULL_END
