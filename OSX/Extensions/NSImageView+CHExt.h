//
//  NSImageView+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImageView (CHExt)

- (instancetype)initWithImage:(NSImage *)image;
- (void)setContentMode:(NSInteger)contentMode;


@end

NS_ASSUME_NONNULL_END
