//
//  CHMainViewController.h
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "CHViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHMainViewController : CHViewController

- (void)pushContentView:(nullable NSView *)contentView;
- (nullable NSView *)topContentView;


@end

NS_ASSUME_NONNULL_END
