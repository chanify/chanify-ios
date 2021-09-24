//
//  CHPageView.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHPageView : CHView

@property (nonatomic, nullable, strong) CHBarButtonItem *rightBarButtonItem;

- (instancetype)initWithParameters:(NSDictionary *)params;
- (BOOL)isEqualToViewController:(__kindof CHPageView *)rhs;
- (NSString *)title;
- (void)viewDidLoad;
- (void)viewDidAppear;
- (void)viewDidDisappear;
- (void)closeAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion;


@end

NS_ASSUME_NONNULL_END
