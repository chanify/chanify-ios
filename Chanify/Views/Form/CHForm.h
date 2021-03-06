//
//  CHForm.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormSection.h"

NS_ASSUME_NONNULL_BEGIN

@class CHFormViewController;

@protocol CHFormDelegate <NSObject>
@optional
- (void)formItemValueHasChanged:(CHFormItem *)item oldValue:(id)oldValue newValue:(id)newValue;
@end

@interface CHForm : NSObject

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, strong) NSHashTable *errorItems;
@property (nonatomic, assign) BOOL assignFirstResponderOnShow;
@property (nonatomic, nullable, weak) id<CHFormDelegate> delegate;
@property (nonatomic, nullable, weak) CHFormViewController *viewController;

+ (instancetype)formWithTitle:(NSString *)title;
- (void)reloadData;
- (NSArray<CHFormSection *> *)sections;
- (void)addFormSection:(CHFormSection *)section;
- (nullable CHFormItem *)formItemWithName:(NSString *)name;
- (NSArray<CHFormInputItem *> *)inputItems;
- (NSDictionary<NSString *, id> *)formValues;


@end

NS_ASSUME_NONNULL_END
