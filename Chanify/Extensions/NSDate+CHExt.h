//
//  NSDate+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/10.
//

#import <Foundation/NSDate.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (CHExt)

+ (nullable instancetype)dateFromMID:(uint64_t)mid;
- (NSString *)shortFormat;
- (NSString *)mediumFormat;


@end

NS_ASSUME_NONNULL_END