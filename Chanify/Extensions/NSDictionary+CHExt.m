//
//  NSDictionary+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSDictionary+CHExt.h"
#import <Foundation/NSJSONSerialization.h>

@implementation NSDictionary (CHExt)

+ (nullable instancetype)dictionaryWithJSONData:(nullable NSData *)data {
    if (data.length > 0) {
        NSError *error = nil;
        id res = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves) error:&error];
        if (error == nil && [res isKindOfClass:self.class]) {
            return res;
        }
    }
    return nil;
}

- (NSData *)json {
    if (self != nil) {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingSortedKeys error:&error];
        if (error == nil) {
            return data;
        }
    }
    return [NSData new];
}


@end
