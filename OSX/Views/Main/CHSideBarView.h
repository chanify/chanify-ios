//
//  CHSideBarView.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHSideBarView : CHView

@property (nonatomic, nullable, strong) CHBarButtonItem *rightBarButtonItem;

- (void)viewDidLoad;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
