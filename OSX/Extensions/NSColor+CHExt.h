//
//  NSColor+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import <AppKit/NSColor.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSColor (CHExt)

+ (instancetype)colorWithRGB:(uint32_t)rgb;
+ (instancetype)systemBackgroundColor;
+ (instancetype)systemGroupedBackgroundColor;


@end

NS_ASSUME_NONNULL_END
