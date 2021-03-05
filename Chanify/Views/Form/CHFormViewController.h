//
//  CHFormViewController.h
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHViewController.h"
#import "CHForm.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHFormViewController : CHViewController

@property (nonatomic, nullable, strong) CHForm *form;

- (void)reloadItem:(CHFormItem *)item;
- (void)showActionSheet:(UIAlertController *)alertController item:(CHFormItem *)item animated:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
