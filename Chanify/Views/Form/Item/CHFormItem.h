//
//  CHFormItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kCHFormTextFieldTag     1000
#define kCHFormImageViewTag     1001
#define kCHFormSwitchViewTag    1002

@class CHFormItem;
@class CHFormSection;

typedef void (^CHFormItemActionBlock)(__kindof CHFormItem *item);
typedef void (^CHFormItemOnChangedBlock)(__kindof CHFormItem *item, __nullable id oldValue, __nullable id newValue);

@interface CHFormItem : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, nullable, strong) NSPredicate *hidden;
@property (nonatomic, nullable, weak) CHFormSection *section;
@property (nonatomic, nullable, copy) CHFormItemActionBlock action;

- (instancetype)initWithName:(NSString *)name;
- (id<UIContentConfiguration>)contentConfiguration;
- (UITableViewCellAccessoryType)accessoryType;
- (void)prepareCell:(UITableViewCell *)cell;
- (void)updateStatus;
- (BOOL)isHidden;


@end

@protocol CHFormEditableItem <NSObject>

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, nullable, strong) id value;
@property (nonatomic, assign) BOOL required;
@property (nonatomic, nullable, copy) CHFormItemOnChangedBlock onChanged;

@end

NS_ASSUME_NONNULL_END
