//
//  CHFormValueItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormValueItem : CHFormItem

@property (nonatomic, readonly, strong) UIListContentConfiguration *configuration;
@property (nonatomic, nullable, strong) id value;
@property (nonatomic, nullable, strong) NSString* copiedName;

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title value:(nullable id)value;
+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title;
- (instancetype)initWithName:(NSString *)name title:(NSString *)title value:(nullable id)value NS_DESIGNATED_INITIALIZER;
- (void)setTitleTextColor:(UIColor *)textColor;
- (void)setIcon:(nullable UIImage *)icon;
- (UITableViewCellAccessoryType)accessoryType;
- (__kindof NSString *)textValue;


@end

NS_ASSUME_NONNULL_END
