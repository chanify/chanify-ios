//
//  CHFormDateItem.h
//  iOS
//
//  Created by WizJin on 2021/5/17.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormDateItem : CHFormValueItem<CHFormEditableItem>

@property (nonatomic, assign) BOOL required;
@property (nonatomic, nullable, copy) CHFormItemOnChangedBlock onChanged;
@property (nonatomic, nullable, strong) NSDate *minimumDate;
@property (nonatomic, nullable, strong) NSDate *maximumDate;


@end

NS_ASSUME_NONNULL_END
