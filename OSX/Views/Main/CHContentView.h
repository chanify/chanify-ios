//
//  CHContentView.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHPageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHContentView : CHView

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, assign) CGFloat headerMarginLeft;
@property (nonatomic, assign) CGFloat headerMarginRight;
@property (nonatomic, assign) CGFloat headerHeight;

- (void)pushPage:(nullable CHPageView *)page animate:(BOOL)animate reset:(BOOL)reset;
- (void)popPage:(nullable CHPageView *)page animate:(BOOL)animate;
- (void)viewDidAppear;
- (void)viewDidDisappear;
- (void)resetContentView;
- (NSInteger)pageCount;
- (nullable CHPageView *)topContentView;


@end

NS_ASSUME_NONNULL_END
