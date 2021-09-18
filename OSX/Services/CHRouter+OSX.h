//
//  CHRouter+OSX.h
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class CHViewController;

@interface CHRouter (OSX)

- (void)launch;
- (void)close;
- (void)handleReopen:(id)sender;
- (void)setBadgeText:(NSString *)badgeText;
- (void)presentViewController:(CHViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
