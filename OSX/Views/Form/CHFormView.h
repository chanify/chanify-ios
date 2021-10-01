//
//  CHFormView.h
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHPageView.h"
#import "CHForm.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormView : CHPageView<CHFormViewDelegate>

@property (nonatomic, nullable, strong) CHForm *form;

- (void)reloadData;
- (void)reloadItem:(CHFormItem *)item;
- (void)reloadSection:(CHFormSection *)section;
- (void)itemBecomeFirstResponder:(CHFormInputItem *)item;
- (nullable CHFormViewCell *)cellForItem:(CHFormItem *)item;
- (__kindof CHView *)itemAccessoryView:(CHFormInputItem *)item;
- (BOOL)itemShouldInputReturn:(CHFormInputItem *)item;
- (BOOL)itemIsLastInput:(CHFormInputItem *)item;
- (void)showActionSheet:(CHAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
