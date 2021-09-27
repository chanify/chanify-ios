//
//  CHContentView.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHPageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHContentView : CHView

- (void)pushPage:(nullable CHPageView *)page animate:(BOOL)animate reset:(BOOL)reset;
- (void)viewDidAppear;
- (void)viewDidDisappear;
- (nullable CHPageView *)topContentView;


@end

NS_ASSUME_NONNULL_END
