//
//  NSDate+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/10.
//

#import <Foundation/NSDate.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (CHExt)

+ (nullable instancetype)dateFromMID:(NSString *)mid;
- (NSString *)shortFormat;
- (NSString *)mediumFormat;
- (NSString *)fullDayFormat;


@end

NS_ASSUME_NONNULL_END
