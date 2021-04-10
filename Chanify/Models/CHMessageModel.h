//
//  CHMessageModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>
#import "CHThumbnailModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CHUserDataSource;
@class UNMutableNotificationContent;
@protocol CHKeyStorage;

typedef NS_ENUM(NSInteger, CHMessageType) {
    CHMessageTypeNone       = -1,
    CHMessageTypeSystem     = 0,
    CHMessageTypeText       = 1,
    CHMessageTypeImage      = 2,
    CHMessageTypeVideo      = 3,
    CHMessageTypeAudio      = 4,
    CHMessageTypeLink       = 5,
    CHMessageTypeFile       = 6,
};

@interface CHMessageModel : NSObject

@property (nonatomic, readonly, strong) NSString *mid;
@property (nonatomic, readonly, assign) CHMessageType type;
@property (nonatomic, readonly, strong) NSString *from;
@property (nonatomic, readonly, strong) NSData *channel;
@property (nonatomic, readonly, nullable, strong) NSString *sound;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, nullable, strong) NSString *text;
@property (nonatomic, readonly, nullable, strong) NSString *file;
@property (nonatomic, readonly, nullable, strong) NSURL *link;
@property (nonatomic, readonly, nullable, strong) NSString *filename;
@property (nonatomic, readonly, nullable, strong) CHThumbnailModel *thumbnail;

+ (nullable instancetype)modelWithData:(nullable NSData *)data mid:(NSString *)mid;
+ (nullable instancetype)modelWithKS:(id<CHKeyStorage>)ks uid:(NSString *)uid mid:(NSString *)mid data:(nullable NSData *)data raw:(NSData * _Nullable * _Nullable)raw;
+ (nullable NSString *)parsePacket:(NSDictionary *)info mid:(NSString * _Nullable * _Nullable)mid data:(NSData * _Nullable * _Nullable)data;
- (void)formatNotification:(UNMutableNotificationContent *)content;
- (NSString *)summaryTextBody;
- (nullable NSString *)fileURL;


@end

NS_ASSUME_NONNULL_END
