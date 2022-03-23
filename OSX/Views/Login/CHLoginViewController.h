//
//  CHLoginViewController.h
//  OSX
//
//  Created by WizJin on 2021/8/31.
//

#import "CHViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLoginViewItem <NSObject>

- (void)setStatusText:(NSString *)text;
- (void)setShowIndicator:(BOOL)bSHow;

@end

@interface CHLoginViewController : CHViewController


@end

NS_ASSUME_NONNULL_END
