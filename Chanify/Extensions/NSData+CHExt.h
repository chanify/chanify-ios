//
//  NSData+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (CHExt)

+ (instancetype)dataFromHex:(nullable NSString *)str;
+ (instancetype)dataFromBase32:(nullable NSString *)str;
+ (instancetype)dataFromBase64:(nullable NSString *)str;
+ (instancetype)dataFromBundleURL:(NSURL *)url;
- (NSString *)hex;
- (NSString *)base32;
- (NSString *)base64;
- (NSData *)sha1;
- (NSData *)sha256;


@end

NS_ASSUME_NONNULL_END
