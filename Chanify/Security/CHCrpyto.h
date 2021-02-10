//
//  CHCrpyto.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHCrpyto : NSObject

+ (nullable NSData *)aesOpenWithKey:(NSData *)key data:(NSData *)data auth:(NSData *)auth;
+ (nullable NSData *)aesSealWithKey:(NSData *)key data:(NSData *)data nonce:(NSData *)nonce auth:(NSData *)auth;

@end

@interface CHCrpyto (HMAC)

+ (NSData *)hmacSha256:(NSData *)payload secret:(NSData *)secret;


@end

NS_ASSUME_NONNULL_END
