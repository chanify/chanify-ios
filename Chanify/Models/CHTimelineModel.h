//
//  CHTimelineModel.h
//  Chanify
//
//  Created by WizJin on 2021/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHTPTimeContent;

@interface CHTimelineModel : NSObject

+ (nullable instancetype)timelineWithContent:(nullable CHTPTimeContent *)content;
- (NSString *)code;
- (NSDate *)timestamp;
- (NSDictionary *)values;
- (NSData *)data;


@end

NS_ASSUME_NONNULL_END
