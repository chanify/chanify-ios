//
//  CHFormValueItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormItem.h"

NS_ASSUME_NONNULL_BEGIN

@class CHFormValueItem;

typedef NSString * _Nullable (^CHFormValueFormatter)(__kindof CHFormValueItem *item, id value);

@interface CHFormValueItem : CHFormItem

@property (nonatomic, readonly, strong) CHListContentConfiguration *configuration;
@property (nonatomic, nullable, strong) id value;
@property (nonatomic, nullable, strong) NSString* copiedName;
@property (nonatomic, nullable, copy) CHFormValueFormatter formatter;

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title value:(nullable id)value;
+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title;
- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value NS_DESIGNATED_INITIALIZER;
- (void)setTitleTextColor:(CHColor *)textColor;
- (void)setIcon:(nullable CHImage *)icon;
- (CHFormViewCellAccessoryType)accessoryType;
- (__kindof NSString *)textValue;


@end

NS_ASSUME_NONNULL_END
