//
//  CHFormViewController.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHViewController.h"
#import "CHForm.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormViewController : CHViewController<CHFormViewDelegate>

@property (nonatomic, nullable, strong) CHForm *form;

- (void)reloadData;
- (void)reloadItem:(CHFormItem *)item;
- (void)reloadSection:(CHFormSection *)section;
- (void)showActionSheet:(UIAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated;
- (nullable UITableViewCell *)cellForItem:(CHFormItem *)item;
- (BOOL)itemIsLastInput:(CHFormInputItem *)item;
- (BOOL)itemShouldInputReturn:(CHFormInputItem *)item;
- (UIToolbar *)itemAccessoryView:(CHFormInputItem *)item;
- (void)itemBecomeFirstResponder:(CHFormInputItem *)item;
- (UIBarButtonItem *)rightBarButtonItem;
- (void)setRightBarButtonItem:(UIBarButtonItem *)item;


@end

NS_ASSUME_NONNULL_END
