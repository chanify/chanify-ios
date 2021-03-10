//
//  CHRouter.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;

@protocol CHMainViewController <NSObject>
- (void)viewReset;
@end


@interface CHRouter : NSObject

@property (nonatomic, readonly, strong) UIWindow *window;

+ (instancetype)shared;
- (void)active;
- (void)deactive;
- (BOOL)canSendMail;
- (BOOL)launchWithOptions:(NSDictionary *)options;
- (BOOL)handleShortcut:(NSString *)type;
- (BOOL)handleURL:(NSURL *)url;
- (BOOL)routeTo:(NSString *)url;
- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params;
- (void)resetDetailViewController;
- (void)popToRootViewControllerAnimated:(BOOL)animated;
- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)presentSystemViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)closeViewController:(UIViewController *)vc animated:(BOOL)animated completion: (void (^ __nullable)(void))completion;
- (void)showShareItem:(NSArray *)items sender:(id)sender handler:(void (^ __nullable)(BOOL completed, NSError * _Nullable error))handler;
- (void)showAlertWithTitle:(NSString *)title action:(NSString *)action handler:(void (^ __nullable)(void))handler;
- (void)showIndicator:(BOOL)show;
- (void)makeToast:(NSString *)message;


@end

NS_ASSUME_NONNULL_END
