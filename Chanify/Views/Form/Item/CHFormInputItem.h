//
//  CHFormInputItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/6.
//

#import "CHFormValueItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHFormInputType) {
    CHFormInputTypeText = 0,
    CHFormInputTypeAccount = 1,
};

@interface CHFormInputItem : CHFormValueItem

@property (nonatomic, assign) BOOL required;
@property (nonatomic, assign) CHFormInputType inputType;

+ (instancetype)itemWithName:(NSString *)name title:(NSString *)title;
- (void)startEditing;
- (__kindof UIView *)editView;


@end

NS_ASSUME_NONNULL_END
