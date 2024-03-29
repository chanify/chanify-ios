//
//  CHNSDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessageModel.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"

NS_ASSUME_NONNULL_BEGIN

@class FMDatabase;

typedef NS_ENUM(NSInteger, CHBannerIconMode) {
    CHBannerIconModeNone    = 0,
    CHBannerIconModeChan    = 1,
    CHBannerIconModeNode    = 2,
};

@protocol CHKeyStorage <NSObject>
- (nullable NSData *)keyForUID:(nullable NSString *)uid;
@end

@protocol CHBlockedStorage <NSObject>
- (BOOL)checkBlockedTokenWithKey:(nullable NSString *)key uid:(nullable NSString *)uid;
@end

@interface CHNSDataSource : NSObject<CHKeyStorage, CHBlockedStorage>

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (void)flush;
- (nullable NSData *)keyForUID:(nullable NSString *)uid;
- (void)updateKey:(nullable NSData *)key uid:(nullable NSString *)uid;
- (NSInteger)syncVersionForUID:(nullable NSString *)uid;
- (void)updateSyncVersion:(NSInteger)version uid:(nullable NSString *)uid;
- (NSString *)notificationSoundForUID:(nullable NSString *)uid;
- (void)updateNotificationSound:(NSString *)sound uid:(nullable NSString *)uid;
- (CHBannerIconMode)bannerIconModeForUID:(nullable NSString *)uid API_AVAILABLE(ios(15.0), macos(12.0), watchos(8.0));
- (void)updateBannerIconMode:(CHBannerIconMode)iconMode uid:(nullable NSString *)uid API_AVAILABLE(ios(15.0), macos(12.0), watchos(8.0));
- (NSUInteger)badgeForUID:(nullable NSString *)uid;
- (NSUInteger)nextBadgeForUID:(nullable NSString *)uid;
- (void)updateBadge:(NSUInteger)badge uid:(nullable NSString *)uid;
- (nullable CHMessageModel *)pushMessage:(NSData *)data mid:(NSString *)mid uid:(NSString *)uid flags:(CHMessageProcessFlags * _Nullable)flags;
- (void)enumerateMessagesWithUID:(nullable NSString *)uid block:(void (NS_NOESCAPE ^)(FMDatabase *db, NSString *mid, NSData *data))block;
- (void)removeMessages:(NSArray<NSString *> *)mids uid:(nullable NSString *)uid;
- (BOOL)upsertBlockedToken:(nullable NSString *)token uid:(nullable NSString *)uid;
- (BOOL)removeBlockedTokens:(NSArray<NSString *> *)tokens uid:(nullable NSString *)uid;
- (NSArray<NSString *> *)blockedTokensWithUID:(nullable NSString *)uid;
// Nodes
- (nullable NSString *)nodeIconWithNID:(nullable NSString *)nid uid:(nullable NSString *)uid;
- (BOOL)upsertNode:(CHNodeModel *)model uid:(nullable NSString *)uid;
- (BOOL)deleteNode:(nullable NSString *)nid uid:(nullable NSString *)uid;
// Channels
- (nullable NSString *)channelIconWithCID:(nullable NSString *)cid uid:(nullable NSString *)uid;
- (BOOL)upsertChannel:(CHChannelModel *)model uid:(nullable NSString *)uid;
- (BOOL)deleteChannel:(nullable NSString *)cid uid:(nullable NSString *)uid;

@end

@interface CHTempNSDatasource : NSObject<CHKeyStorage, CHBlockedStorage>
+ (instancetype)datasourceFromDB:(FMDatabase *)db;
@end


NS_ASSUME_NONNULL_END
