//
//  CHLogic+iOS.h
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic.h"
#import "CHWebObjectManager.h"

NS_ASSUME_NONNULL_BEGIN

@class UIImage;
@class CHWebFileManager;
@class CHLinkMetaManager;

@protocol CHLogicDelegate <CHCommonLogicDelegate>
@optional
- (void)logicWatchStatusChanged;
@end

@interface CHLogic : CHCommonLogic<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;
@property (nonatomic, nullable, readonly, strong) CHLinkMetaManager *linkMetaManager;
@property (nonatomic, nullable, readonly, strong) CHWebFileManager *webFileManager;
@property (nonatomic, nullable, readonly, strong) CHWebObjectManager<UIImage *> *webImageManager;

- (void)launch;
// API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion;
// Read & Unread
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (void)addReadChannel:(nullable NSString *)cid;
- (void)removeReadChannel:(nullable NSString *)cid;
// Watch
- (BOOL)hasWatch;
- (BOOL)isWatchAppInstalled;
- (BOOL)syncDataToWatch:(BOOL)focus;


@end

NS_ASSUME_NONNULL_END
