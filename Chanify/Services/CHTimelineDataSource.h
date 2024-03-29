//
//  CHTimelineDataSource.h
//  iOS
//
//  Created by WizJin on 2021/8/20.
//

#import <Foundation/Foundation.h>
#import "CHTimelineModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CHTPTimeContent;

@interface CHTimelineDataSource : NSObject

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (void)flush;
- (BOOL)upsertUid:(NSString *)uid from:(NSString *)from model:(nullable CHTimelineModel *)model;
- (nullable CHTimelineModel *)modelWithUid:(NSString *)uid code:(NSString *)code from:(NSString *)from point:(NSDate *)point;


@end

NS_ASSUME_NONNULL_END
