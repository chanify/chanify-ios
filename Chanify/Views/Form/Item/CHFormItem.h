//
//  CHFormItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CHFormItem;
@class CHFormViewController;

typedef void (^CHFormItemActionBlock)(__kindof CHFormItem *item);
typedef void (^CHFormItemOnChangedBlock)(__kindof CHFormItem *item, __nullable id newValue, __nullable id oldValue);

@interface CHFormItem : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, nullable, strong) NSPredicate *hidden;
@property (nonatomic, nullable, weak) CHFormViewController *viewController;
@property (nonatomic, nullable, copy) CHFormItemActionBlock action;

- (instancetype)initWithName:(NSString *)name;
- (id<UIContentConfiguration>)contentConfiguration;
- (UITableViewCellAccessoryType)accessoryType;
- (void)setIcon:(nullable UIImage *)icon;
- (BOOL)isHidden;


@end

NS_ASSUME_NONNULL_END
