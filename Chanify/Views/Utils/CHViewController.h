//
//  CHViewController.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#if TARGET_OS_OSX

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHViewController : NSViewController

@end

NS_ASSUME_NONNULL_END

#else

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHViewController : UIViewController

- (BOOL)isEqualToViewController:(__kindof CHViewController *)rhs;


@end

NS_ASSUME_NONNULL_END

#endif
