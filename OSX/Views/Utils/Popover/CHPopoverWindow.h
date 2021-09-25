//
//  CHPopoverWindow.h
//  OSX
//
//  Created by WizJin on 2021/9/26.
//

#import "CHPageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHPopoverWindow : NSWindow

+ (instancetype)windowWithPage:(CHPageView *)page;
- (void)run;


@end

NS_ASSUME_NONNULL_END
