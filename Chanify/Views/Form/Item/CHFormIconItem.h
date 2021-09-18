//
//  CHFormIconItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormIconItem : CHFormValueItem<CHFormEditableItem>

@property (nonatomic, assign) BOOL required;
@property (nonatomic, nullable, copy) CHFormItemOnChangedBlock onChanged;


@end

NS_ASSUME_NONNULL_END
