//
//  CHLogic+watchOS.h
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogicBase.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHWatchConfigurationStatus) {
    CHWatchConfigurationStatusWaiting,
    CHWatchConfigurationStatusReceived,
    CHWatchConfigurationStatusFailed,
};

@protocol CHLogicDelegate <CHLogicBaseDelegate>
@optional
- (void)logicWatchConfigurationChanged;
- (void)logicWatchMessagesChanged;
- (void)logicWatchOpenMessage:(NSString *)mid;
- (void)logicUserInfoChanged:(nullable CHUserModel *)me;
@end

@interface CHLogic : CHLogicBase<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;
@property (nonatomic, readonly) CHWatchConfigurationStatus configurationStatus;
@property (nonatomic, nullable, readonly, strong) NSDate *lastConfigurationDate;
// Reapply the last delivered context; this does not request data from the phone.
- (void)retryWatchConfiguration;
@property (nonatomic, readonly) BOOL processingInbox;
@property (nonatomic, readonly) BOOL inboxHasPendingMessages;
@property (nonatomic, nullable, readonly, copy) NSString *pendingMessageID;
- (void)refreshWatchMessages;
- (void)consumePendingMessageID:(NSString *)mid;


@end

NS_ASSUME_NONNULL_END
