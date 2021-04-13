//
//  CHLoadingView.h
//  Chanify
//
//  Created by WizJin on 2021/4/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHLoadingView : UIView

@property (nonatomic, assign) CGFloat progress;

+ (instancetype)loadingViewWithTarget:(nullable id)target action:(nullable SEL)action;
- (void)reset;
- (void)switchToFailed;
- (void)stop:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
