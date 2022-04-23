//
//  CHLogic.h
//  iOS
//
//  Created by WizJin on 2021/6/9.
//

#import "CHLogicBase.h"

NS_ASSUME_NONNULL_BEGIN

@class CHScriptModel;
@class CHMessageModel;
@class CHScriptManager;
@class CHWebLinkManager;
@class CHWebFileManager;
@class CHWebImageManager;
@class CHWebAudioManager;

@protocol CHLogicDelegate <CHLogicBaseDelegate>
@optional
- (void)logicMessageDeleted:(CHMessageModel *)mid;
- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids;
- (void)logicMessagesCleared:(NSString *)cid;
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids;
- (void)logicMessagesUnreadChanged:(NSNumber *)unread;
// Script
- (void)logicScriptListUpdated:(NSArray<NSString *> *)snames;
// iOS
- (void)logicWatchStatusChanged API_AVAILABLE(ios(14.0));
- (void)logicNotificationSoundChanged API_AVAILABLE(ios(14.0));
@end

@interface CHAppLogic : CHLogicBase<id<CHLogicDelegate>>

@property (nonatomic, readonly, assign) BOOL isAutoDownload;
@property (nonatomic, nullable, readonly, strong) CHWebLinkManager *webLinkManager;
@property (nonatomic, nullable, readonly, strong) CHWebFileManager *webFileManager;
@property (nonatomic, nullable, readonly, strong) CHWebImageManager *webImageManager;
@property (nonatomic, nullable, readonly, strong) CHWebAudioManager *webAudioManager;
@property (nonatomic, nullable, readonly, strong) CHScriptManager *scriptManager;

- (instancetype)initWithAppGroup:(NSString *)appGroup;
// Messages
- (BOOL)deleteMessage:(nullable NSString *)mid;
- (BOOL)deleteMessages:(NSArray<NSString *> *)mids;
- (BOOL)deleteMessagesWithCID:(nullable NSString *)cid;
// Channel
- (void)updateChannelHidden:(BOOL)hidden cid:(nullable NSString *)cid;
// Script
- (BOOL)insertScript:(CHScriptModel *)model;
- (BOOL)deleteScript:(NSString *)name;
- (BOOL)updateScript:(NSString *)name content:(nullable NSString *)content;
// Read & Unread
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (void)addReadChannel:(nullable NSString *)cid;
- (void)removeReadChannel:(nullable NSString *)cid;
- (BOOL)isReadChannel:(NSString *)cid;
- (NSArray<NSString *> *)readChannelIDs; // TODO: try remove
// Subclass
- (void)reloadUserDB:(BOOL)force;
- (BOOL)clearUnreadWithChannel:(nullable NSString *)cid;


@end

NS_ASSUME_NONNULL_END

#if TARGET_OS_OSX
#   import "CHLogic+OSX.h"
#else
#   import "CHLogic+iOS.h"
#endif
