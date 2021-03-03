//
//  CHIndicatorView.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHIndicatorView : UIView

@property (nonatomic, assign) CGFloat gap;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat lineWidth;

- (void)startAnimating;
- (void)stopAnimating:(nullable dispatch_block_t)complation;


@end

NS_ASSUME_NONNULL_END
