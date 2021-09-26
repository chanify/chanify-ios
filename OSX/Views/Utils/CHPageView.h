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
@property (nonatomic, nullable, weak) id<CHPageViewDelegate> delegate;

- (instancetype)initWithParameters:(NSDictionary *)params;
- (BOOL)isEqualWithParameters:(NSDictionary *)params;
- (void)viewDidLoad;
- (void)viewDidAppear;
- (void)viewDidDisappear;
- (void)closeAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion;


@end

NS_ASSUME_NONNULL_END
