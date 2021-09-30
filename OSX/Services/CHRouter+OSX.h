//
//  CHRouter+OSX.h
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class CHPageView;

@interface CHRouter (OSX)

- (void)launch;
- (void)close;
- (BOOL)handleReopen:(id)sender hasVisibleWindows:(BOOL)flag;
- (void)setBadgeText:(NSString *)badgeText;
- (void)pushViewController:(CHPageView *)page animated:(BOOL)animated;
- (void)showIndicator:(BOOL)show;


@end

NS_ASSUME_NONNULL_END
