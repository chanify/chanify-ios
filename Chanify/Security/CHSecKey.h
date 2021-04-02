//
//  CHSecKey.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHSecKey : NSObject

+ (nullable instancetype)secKeyWithName:(NSString *)name device:(BOOL)device created:(BOOL)created;
+ (nullable instancetype)secKeyWithPublicKeyData:(nullable NSData *)data;
+ (nullable instancetype)secKeyWithData:(nullable NSData *)data;
- (instancetype)init;
- (BOOL)saveTo:(NSString *)name device:(BOOL)device;
- (BOOL)deleteWithName:(NSString *)name device:(BOOL)device;
- (BOOL)verify:(NSData *)data sign:(NSData *)sign;
- (NSString *)formatID:(uint8_t)code;
- (NSData *)encode:(NSData *)data;
- (NSData *)decode:(NSData *)data;
- (NSData *)sign:(NSData *)data;
- (NSData *)uuid;
- (NSData *)seckey;
- (NSData *)pubkey;


@end

NS_ASSUME_NONNULL_END
