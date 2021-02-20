//
//  CHRouter.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;

@interface CHRouter : NSObject

@property (nonatomic, readonly, strong) UIWindow *window;

+ (instancetype)shared;
- (void)active;
- (void)deactive;
- (BOOL)canSendMail;
- (BOOL)launchWithOptions:(NSDictionary *)options;
- (BOOL)handleURL:(NSURL *)url;
- (BOOL)routeTo:(NSString *)url;
- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params;
- (void)popToRootViewControllerAnimated:(BOOL)animated;
- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)presentSystemViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)showAlertWithTitle:(NSString *)title action:(NSString *)action handler:(void (^ __nullable)(void))handler;
- (void)showIndicator:(BOOL)show;
- (void)makeToast:(NSString *)message;


@end

NS_ASSUME_NONNULL_END
