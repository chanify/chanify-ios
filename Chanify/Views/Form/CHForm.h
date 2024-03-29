//
//  CHForm.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormSection.h"

NS_ASSUME_NONNULL_BEGIN

@class CHAlertController;
@class CHFormViewController;

@protocol CHFormDelegate <NSObject>
@optional
- (void)formItemValueHasChanged:(CHFormItem *)item oldValue:(id)oldValue newValue:(id)newValue;
@end

@protocol CHFormViewDelegate <NSObject>
- (void)reloadItem:(CHFormItem *)item;
- (void)itemBecomeFirstResponder:(CHFormInputItem *)item;
- (nullable CHFormViewCell *)cellForItem:(CHFormItem *)item;
- (__kindof CHView *)itemAccessoryView:(CHFormInputItem *)item;
- (BOOL)itemShouldInputReturn:(CHFormInputItem *)item;
- (BOOL)itemIsLastInput:(CHFormInputItem *)item;
- (void)showActionSheet:(CHAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated;
@end

@interface CHForm : NSObject

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, strong) NSHashTable *errorItems;
@property (nonatomic, assign) BOOL assignFirstResponderOnShow;
@property (nonatomic, nullable, weak) id<CHFormDelegate> delegate;
@property (nonatomic, nullable, weak) id<CHFormViewDelegate> viewDelegate;

+ (instancetype)formWithTitle:(NSString *)title;
- (void)reloadData;
- (NSArray<CHFormSection *> *)sections;
- (NSArray<CHFormSection *> *)allSections;
- (void)addFormSection:(CHFormSection *)section;
- (nullable CHFormItem *)formItemWithName:(NSString *)name;
- (NSArray<CHFormInputItem *> *)inputItems;
- (NSDictionary<NSString *, id> *)formValues;
- (void)notifyItemValueHasChanged:(id<CHFormEditableItem>)item oldValue:(id)oldValue newValue:(id)newValue;


@end

NS_ASSUME_NONNULL_END
