//
//  CHLoginQrCodeView.h
//  OSX
//
//  Created by WizJin on 2021/8/31.
//

#import "CHUI.h"
#import "CHLoginViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLoginQrCodeViewDelegate <NSObject>
- (void)loginWithQrCode:(NSURL *)url;
@end

@interface CHLoginQrCodeView : CHView<CHLoginViewItem>

@property (nonatomic, weak) id<CHLoginQrCodeViewDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
