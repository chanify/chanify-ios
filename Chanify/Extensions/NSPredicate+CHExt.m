//
//  NSPredicate+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSPredicate+CHExt.h"

@implementation NSPredicate (CHExt)

+ (instancetype)predicateWithObject:(id)obj attribute:(NSString *)name {
    return [self.class predicateWithObject:obj attribute:name expected:@YES];
}

+ (instancetype)predicateWithObject:(id)obj attribute:(NSString *)name expected:(id)expected {
    return [[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"$v.%@=%@", name, expected]] predicateWithSubstitutionVariables:@{ @"v": obj }];
}


@end
