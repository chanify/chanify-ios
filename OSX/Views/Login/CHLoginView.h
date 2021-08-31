//
//  CHLoginView.h
//  OSX
//
//  Created by WizJin on 2021/8/31.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLoginViewDelegate <NSObject>
- (void)loginWithQrCode:(NSURL *)url;
@end

@interface CHLoginView : CHView

@property (nonatomic, weak) id<CHLoginViewDelegate> delegate;

- (void)setStatusText:(NSString *)text;
- (void)setShowIndicator:(BOOL)bSHow;


@end

NS_ASSUME_NONNULL_END
