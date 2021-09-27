//
//  CHMainViewController.h
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "CHViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CHPageView;

@interface CHMainViewController : CHViewController

- (nullable CHPageView *)topContentView;
- (void)pushPage:(nullable CHPageView *)page animate:(BOOL)animate reset:(BOOL)reset;


@end

NS_ASSUME_NONNULL_END
