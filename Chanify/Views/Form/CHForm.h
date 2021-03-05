//
//  CHForm.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHForm : NSObject

@property (nonatomic, readonly, strong) NSString *title;

+ (instancetype)formWithTitle:(NSString *)title;
- (void)setViewController:(CHFormViewController *)viewController;
- (NSArray<CHFormSection *> *)sections;
- (void)addFormSection:(CHFormSection *)section;
- (nullable CHFormItem *)formItemWithName:(NSString *)name;


@end

NS_ASSUME_NONNULL_END
