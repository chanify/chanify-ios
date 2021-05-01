//
//  CHScanViewController.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHScanViewControllerDelegate <NSObject>
- (void)scanFindURL:(NSURL *)url;
@end

@interface CHScanViewController : CHViewController

@property (nonatomic, nullable, weak) id<CHScanViewControllerDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
