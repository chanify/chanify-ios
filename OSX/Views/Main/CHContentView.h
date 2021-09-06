//
//  CHContentView.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHPageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHContentView : CHView

@property (nonatomic, nullable, strong) CHPageView *contentView;

- (void)viewDidAppear;
- (void)viewDidDisappear;


@end

NS_ASSUME_NONNULL_END
