//
//  CHRouter+iOS.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class UIWindow;
@class UIViewController;
@class UIAlertController;

@protocol CHMainViewController <NSObject>
- (void)viewReset;
@end

@interface CHRouter (iOS)

- (void)active;
- (void)deactive;
- (BOOL)canSendMail;
- (BOOL)launchWithOptions:(NSDictionary *)options;
- (BOOL)handleShortcut:(NSString *)type;
- (void)shouldChangeDetailViewControllerTo:(UIViewController *)vc;
- (void)popToRootViewControllerAnimated:(BOOL)animated;
- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)presentSystemViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)closeViewController:(UIViewController *)vc animated:(BOOL)animated completion: (void (^ __nullable)(void))completion;
- (void)showAlertView:(UIAlertController *)alert;
- (void)showIndicator:(BOOL)show;


@end

NS_ASSUME_NONNULL_END
