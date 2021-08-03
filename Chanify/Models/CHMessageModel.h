//
//  CHMessageModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>
#import "CHThumbnailModel.h"
#import "CHActionItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CHUserDataSource;
@class UNMutableNotificationContent;
@protocol CHKeyStorage;
@protocol CHBlockedStorage;

typedef NS_ENUM(NSInteger, CHMessageType) {
    CHMessageTypeNone       = -1,
    CHMessageTypeSystem     = 0,
    CHMessageTypeText       = 1,
    CHMessageTypeImage      = 2,
    CHMessageTypeVideo      = 3,
    CHMessageTypeAudio      = 4,
    CHMessageTypeLink       = 5,
    CHMessageTypeFile       = 6,
    CHMessageTypeAction     = 7,
    CHMessageTypeTimeline   = 8,
};

typedef NS_OPTIONS(NSUInteger, CHMessageFlags) {
    CHMessageFlagAutoCopy   = 1 << 0,
};

typedef NS_OPTIONS(NSUInteger, CHMessageProcessFlags) {
    CHMessageProcessFlagNoAlert   = 1 << 0,
    CHMessageProcessFlagBlocked   = (1 << 1 | CHMessageProcessFlagNoAlert),
};


@interface CHMessageModel : NSObject

@property (nonatomic, readonly, strong) NSString *mid;
@property (nonatomic, readonly, assign) CHMessageType type;
@property (nonatomic, readonly, assign) CHMessageFlags flags;
@property (nonatomic, readonly, assign) uint64_t fileSize;
@property (nonatomic, readonly, assign) uint64_t duration;
@property (nonatomic, readonly, strong) NSString *from;
@property (nonatomic, readonly, strong) NSData *channel;
@property (nonatomic, readonly, nullable, strong) NSString *sound;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, nullable, strong) NSString *text;
@property (nonatomic, readonly, nullable, strong) NSString *file;
@property (nonatomic, readonly, nullable, strong) NSURL *link;
@property (nonatomic, readonly, nullable, strong) NSString *filename;
@property (nonatomic, readonly, nullable, strong) CHThumbnailModel *thumbnail;
@property (nonatomic, readonly, nullable, strong) NSString *copytext;
@property (nonatomic, readonly, nullable, strong) NSArray<CHActionItemModel *> *actions;

+ (nullable instancetype)modelWithData:(nullable NSData *)data mid:(NSString *)mid;
+ (nullable instancetype)modelWithStorage:(id<CHKeyStorage, CHBlockedStorage>)storage uid:(NSString *)uid mid:(NSString *)mid data:(nullable NSData *)data raw:(NSData * _Nullable * _Nullable)raw flags:(CHMessageProcessFlags *_Nullable)flags;
+ (nullable NSString *)parsePacket:(NSDictionary *)info mid:(NSString * _Nullable * _Nullable)mid data:(NSData * _Nullable * _Nullable)data;

- (void)formatNotification:(UNMutableNotificationContent *)content;
- (NSString *)summaryText;
- (NSString *)summaryBodyText;
- (nullable NSString *)fileURL;
- (nullable NSString *)copyTextString;
- (BOOL)needNoAlert;


@end

NS_ASSUME_NONNULL_END
