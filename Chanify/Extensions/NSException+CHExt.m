//
//  NSException+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSException+CHExt.h"

@implementation NSException (CHExt)

+ (instancetype)exceptionWithReason:(nullable NSString *)reason {
    return [self.class exceptionWithName:@"CHException" reason:reason userInfo:nil];
}


@end
