//
//  NSPredicate+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSPredicate.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSPredicate (CHExt)

+ (instancetype)predicateWithObject:(id)obj attribute:(NSString *)name;
+ (instancetype)predicateWithObject:(id)obj attribute:(NSString *)name expected:(id)expected;


@end

NS_ASSUME_NONNULL_END
