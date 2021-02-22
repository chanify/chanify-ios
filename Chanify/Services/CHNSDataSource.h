//
//  CHNSDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHNSDataSource : NSObject

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (nullable NSData *)keyForUID:(nullable NSString *)uid;
- (void)updateKey:(nullable NSData *)key uid:(nullable NSString *)uid;
- (NSUInteger)badgeForUID:(nullable NSString *)uid;
- (NSUInteger)nextBadgeForUID:(nullable NSString *)uid;
- (void)updateBadge:(NSUInteger)badge uid:(nullable NSString *)uid;
- (nullable CHMessageModel *)pushMessage:(NSData *)data mid:(NSString *)mid uid:(NSString *)uid;
- (void)enumerateMessagesWithUID:(nullable NSString *)uid block:(void (NS_NOESCAPE ^)(NSString *mid, NSData *data))block;
- (void)removeMessages:(NSArray<NSString *> *)mids uid:(nullable NSString *)uid;


@end

NS_ASSUME_NONNULL_END
