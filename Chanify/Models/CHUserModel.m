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
        _uid = [key formatID:0x00];
        _key = key;
    }
    return self;
}


@end
