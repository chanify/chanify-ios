//
//  NSImage+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/5/3.
//

#import <AppKit/NSImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (CHExt)

+ (instancetype)systemImageNamed:(NSString *)name;
+ (nullable instancetype)imageWithData:(NSData *)data;
- (NSImage *)imageWithTintColor:(NSColor *)color;


@end

NS_ASSUME_NONNULL_END
