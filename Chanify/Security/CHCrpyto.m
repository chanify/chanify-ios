//
//  CHCrpyto.m
//  Chanify
//
//  Created by WizJin on 2021/2/10.
//

#import "CHCrpyto.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation CHCrpyto (HMAC)

+ (NSData *)hmacSha256:(NSData *)payload secret:(NSData *)secret {
    NSMutableData *mac = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, secret.bytes, secret.length, payload.bytes, payload.length, mac.mutableBytes);
    return mac;
}


@end
