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

- (void)pushContentView:(nullable CHPageView *)contentView;
- (nullable CHPageView *)topContentView;


@end

NS_ASSUME_NONNULL_END
