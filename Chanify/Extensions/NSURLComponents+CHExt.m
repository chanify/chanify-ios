//
//  NSURLComponents+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/6/18.
//

#import "NSURLComponents+CHExt.h"

@implementation NSURLComponents (CHExt)

- (nullable NSString *)queryValueForName:(NSString *)name {
    NSString *value = nil;
    for (NSURLQueryItem *item in self.queryItems) {
        if ([item.name isEqualToString:name]) {
            value = item.value;
            break;
        }
    }
    return value;
}


@end
