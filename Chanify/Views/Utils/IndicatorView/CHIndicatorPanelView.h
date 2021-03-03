//
//  CHIndicatorPanelView.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHIndicatorPanelView : UIView

- (void)startAnimating;
- (void)stopAnimating:(dispatch_block_t)complation;


@end

NS_ASSUME_NONNULL_END
