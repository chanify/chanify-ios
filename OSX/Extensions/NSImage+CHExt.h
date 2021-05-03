//
//  NSImage+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/5/3.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (CHExt)

+ (instancetype)systemImageNamed:(NSString *)name;
+ (nullable instancetype)imageWithData:(NSData *)data;


@end

NS_ASSUME_NONNULL_END
