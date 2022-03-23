//
//  CHLoginAccountView.h
//  OSX
//
//  Created by WizJin on 2022/3/23.
//

#import "CHUI.h"
#import "CHLoginViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLoginAccountViewDelegate <NSObject>
- (void)loginWithAccount:(NSString *)account;
@end

@interface CHLoginAccountView : CHView<CHLoginViewItem>

@property (nonatomic, weak) id<CHLoginAccountViewDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
