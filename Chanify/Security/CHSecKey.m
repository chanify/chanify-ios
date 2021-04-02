//
//  CHSecKey.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSecKey.h"
#import <Security/Security.h>

#define kCHSecKeyCommon                                                         \
    (__bridge id)kSecClass: (__bridge id)kSecClassKey,                          \
    (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeECSECPrimeRandom, \

#define kCHSecKeyAccessible \
    (__bridge id)kSecAttrAccessGroup: @kCHAppKeychainName,                      \
    (__bridge id)kSecAttrAccessible: (__bridge id)(device ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly : kSecAttrAccessibleAfterFirstUnlock),                                                    \
    (__bridge id)kSecAttrSynchronizable: (__bridge id)(device ? kCFBooleanFalse : kCFBooleanTrue),  \

#define kCHSecKeyAlgorithm  kSecKeyAlgorithmECIESEncryptionCofactorVariableIVX963SHA256AESGCM

@interface CHSecKey () {
@private
    SecKeyRef secKey;
    SecKeyRef pubKey;
}

@end

@implementation CHSecKey

+ (nullable instancetype)secKeyWithName:(NSString *)name device:(BOOL)device created:(BOOL)created {
    SecKeyRef key = NULL;
    NSDictionary *attributes = @{
        kCHSecKeyCommon
        kCHSecKeyAccessible
        (__bridge id)kSecAttrApplicationTag: name,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecReturnRef: (__bridge id)kCFBooleanTrue,
    };
    if (SecItemCopyMatching((__bridge CFDictionaryRef)attributes, (CFTypeRef *)&key) == errSecItemNotFound && created) {
        attributes = @{
            kCHSecKeyCommon
            kCHSecKeyAccessible
            (__bridge id)kSecAttrKeySizeInBits: @kCHSecKeySizeInBits,
            (__bridge id)kSecPrivateKeyAttrs: @{
                (__bridge id)kSecAttrApplicationTag: name,
                (__bridge id)kSecAttrIsPermanent: (__bridge id)kCFBooleanTrue,
            },
        };
        key = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, NULL);
    }
    if (key != NULL) {
        return [[self.class alloc] initWithSecKey:key];
    }
    return nil;
}

+ (nullable instancetype)secKeyWithPublicKeyData:(nullable NSData *)data {
    if (data.length > 0) {
        NSDictionary *attributes = @{
            kCHSecKeyCommon
            (__bridge id)kSecAttrKeySizeInBits: @kCHSecKeySizeInBits,
            (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
        };
        SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)attributes, nil);
        if (key != NULL) {
            return [[self.class alloc] initWithPubKey:key];
        }
    }
    return nil;
}

+ (nullable instancetype)secKeyWithData:(nullable NSData *)data {
    if (data.length > 0) {
        NSDictionary *attributes = @{
            kCHSecKeyCommon
            (__bridge id)kSecAttrKeySizeInBits: @kCHSecKeySizeInBits,
            (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
        };
        SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)attributes, nil);
        if (key != NULL) {
            return [[self.class alloc] initWithSecKey:key];
        }
    }
    return nil;
}

- (instancetype)init {
    SecKeyRef key = NULL;
    NSDictionary *attributes = @{
        kCHSecKeyCommon
        (__bridge id)kSecAttrKeySizeInBits: @kCHSecKeySizeInBits,
        (__bridge id)kSecPrivateKeyAttrs: @{
            (__bridge id)kSecAttrIsPermanent: (__bridge id)kCFBooleanFalse,
        },
    };
    key = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, NULL);
    if (key == NULL) {
        @throw [NSException exceptionWithReason:@"Create security key failed"];
    }
    return [self initWithSecKey:key];
}

- (instancetype)initWithSecKey:(SecKeyRef)key {
    if (self = [super init]) {
        secKey = key;
        pubKey = SecKeyCopyPublicKey(key);
    }
    return self;
}

- (instancetype)initWithPubKey:(SecKeyRef)key {
    if (self = [super init]) {
        secKey = NULL;
        pubKey = key;
    }
    return self;
}

- (void)dealloc {
    if (pubKey != NULL) {
        CFRelease(pubKey);
        pubKey = NULL;
    }
    if (secKey != NULL) {
        CFRelease(secKey);
        secKey = NULL;
    }
}

- (BOOL)saveTo:(NSString *)name device:(BOOL)device {
    BOOL res = NO;
    NSDictionary *attributes = @{
        kCHSecKeyCommon
        kCHSecKeyAccessible
        (__bridge id)kSecAttrKeySizeInBits: @kCHSecKeySizeInBits,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
        (__bridge id)kSecAttrApplicationTag: name,
        (__bridge id)kSecAttrIsPermanent: (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecValueData: self.seckey,
    };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if (status == errSecDuplicateItem) {
        NSDictionary *query = @{
            kCHSecKeyCommon
            kCHSecKeyAccessible
            (__bridge id)kSecAttrKeySizeInBits: @kCHSecKeySizeInBits,
            (__bridge id)kSecAttrApplicationTag: name,
        };
        if (SecItemDelete((__bridge CFDictionaryRef)query) == errSecSuccess) {
            status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
        }
    }
    if (status == errSecSuccess) {
        res = YES;
    }
    return res;
}

- (BOOL)deleteWithName:(NSString *)name device:(BOOL)device {
    NSDictionary *attributes = @{
        kCHSecKeyCommon
        kCHSecKeyAccessible
        (__bridge id)kSecAttrApplicationTag: name,
    };
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)attributes);
    return (status == errSecItemNotFound || status == errSecSuccess);
}

- (BOOL)verify:(NSData *)data sign:(NSData *)sign {
    BOOL res = NO;
    if (pubKey != NULL) {
        res = SecKeyVerifySignature(pubKey, kSecKeyAlgorithmECDSASignatureMessageX962SHA256, (CFDataRef)data, (CFDataRef)sign, NULL);
    }
    return res;
}

- (NSString *)formatID:(uint8_t)code {
    NSString *res = @"";
    if (self != nil) {
        NSData *key = self.pubkey;
        NSMutableData *data = [NSMutableData dataWithData:key.sha256];
        [data appendData:key];
        key = data.sha1;
        data.length = 1;
        *(uint8_t *)data.mutableBytes = code;
        [data appendData:key];
        res = data.base32;
    }
    return res;
}

- (NSData *)encode:(NSData *)data {
    if (data.length > 0) {
        CFErrorRef error = NULL;
        CFDataRef pData = SecKeyCreateEncryptedData(pubKey, kCHSecKeyAlgorithm, (__bridge CFDataRef)data, &error);
        if (pData != NULL) {
            return CFBridgingRelease(pData);
        }
    }
    return [NSData new];
}

- (NSData *)decode:(NSData *)data {
    if (data.length > 0 && secKey != NULL) {
        CFErrorRef error = NULL;
        CFDataRef pData = SecKeyCreateDecryptedData(secKey, kCHSecKeyAlgorithm, (__bridge CFDataRef)data, &error);
        if (pData != NULL) {
            return CFBridgingRelease(pData);
        }
    }
    return [NSData new];
}

- (NSData *)sign:(NSData *)data {
    if (secKey != NULL) {
        return CFBridgingRelease(SecKeyCreateSignature(secKey, kSecKeyAlgorithmECDSASignatureMessageX962SHA256, (CFDataRef)data, NULL));
    }
    return [NSData new];
}

- (NSData *)uuid {
    return self.pubkey.sha1;
}

- (NSData *)seckey {
    if (secKey != NULL) {
        return CFBridgingRelease(SecKeyCopyExternalRepresentation(secKey, NULL));
    }
    return [NSData new];
}

- (NSData *)pubkey {
    if (pubKey != NULL) {
        return CFBridgingRelease(SecKeyCopyExternalRepresentation(pubKey, NULL));
    }
    return [NSData new];
}


@end
