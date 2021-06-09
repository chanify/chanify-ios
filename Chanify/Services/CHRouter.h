//
//  CHRouter.h
//  iOS
//
//  Created by WizJin on 2021/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_OSX
#   define CHWindow NSWindow
#else
#   define CHWindow UIWindow
#endif

@interface CHRouter : NSObject

@property (nonatomic, readonly, strong) CHWindow *window;

+ (instancetype)shared;

- (BOOL)handleURL:(NSURL *)url;
- (BOOL)routeTo:(NSString *)url;
- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params;
- (void)showShareItem:(NSArray *)items sender:(id)sender handler:(void (^ __nullable)(BOOL completed, NSError *error))handler;
- (void)showAlertWithTitle:(NSString *)title action:(NSString *)action handler:(void (^ __nullable)(void))handler;
- (void)makeToast:(NSString *)message;


@end

NS_ASSUME_NONNULL_END

#if TARGET_OS_OSX
#   import "CHRouter+OSX.h"
#else
#   import "CHRouter+iOS.h"
#endif
