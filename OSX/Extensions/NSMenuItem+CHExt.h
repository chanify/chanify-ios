//
//  NSMenuItem+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import <AppKit/NSMenuItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMenuItem (CHExt)

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
