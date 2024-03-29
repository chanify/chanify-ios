//
//  CHPageView.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHPageViewDelegate <NSObject>
- (void)titleUpdated;
@end

@interface CHPageView : CHView

@property (nonatomic, nullable, strong) CHBarButtonItem *rightBarButtonItem;
@property (nonatomic, nullable, strong) NSString *title;
@property (nonatomic, nullable, weak) id<CHPageViewDelegate> pageDelegate;

- (instancetype)initWithParameters:(NSDictionary *)params;
- (BOOL)isEqualWithParameters:(NSDictionary *)params;
- (CHView *)view;
- (void)viewDidLoad;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (CGSize)calcContentSize;
- (void)closeAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion;


@end

NS_ASSUME_NONNULL_END
