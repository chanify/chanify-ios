//
//  CHUserModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserModel.h"

@implementation CHUserModel

+ (nullable instancetype)modelWithKey:(nullable CHSecKey *)key {
    if (key != nil) {
        return [[self.class alloc] initWithKey:key];
    }
    return nil;
}

- (instancetype)initWithKey:(nullable CHSecKey *)key {
    if (self = [super init]) {
        _uid = calc_userid(key);
        _key = key;
    }
    return self;
}

#pragma mark - Private Methods
static inline NSString *calc_userid(CHSecKey *seckey) {
    NSData *key = seckey.pubkey;
    NSMutableData *data = [NSMutableData dataWithData:key.sha256];
    [data appendData:key];
    key = data.sha1;
    data.length = 1;
    *(uint8_t *)data.mutableBytes = 0x00;
    [data appendData:key];
    return data.base32;
}


@end
