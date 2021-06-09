//
//  CHContentView.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHContentView : NSView

@property (nonatomic, nullable, strong) NSView *contentView;

- (void)viewDidAppear;
- (void)viewDidDisappear;


@end

NS_ASSUME_NONNULL_END
