//
//  CHLogic+iOS.h
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic.h"
#import "CHSoundManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHLogicDownloadMode) {
    CHLogicDownloadModeAuto     = 0,
    CHLogicDownloadModeManual   = 1,
    CHLogicDownloadModeWifiOnly = 2,
};

@interface CHLogic : CHAppLogic

+ (instancetype)shared;

@property (nonatomic, assign) CHLogicDownloadMode downloadMode;
@property (nonatomic, readonly, strong) CHSoundManager *soundManager;
@property (nonatomic, nullable, strong) NSString *defaultNotificationSound;

// API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion;
// Nodes
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion;
// Watch
- (BOOL)hasWatch;
- (BOOL)isWatchAppInstalled;
- (BOOL)syncDataToWatch:(BOOL)focus;


@end

NS_ASSUME_NONNULL_END
