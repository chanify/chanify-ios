//
//  CHLogic+OSX.h
//  OSX
//
//  Created by WizJin on 2021/5/2.
//

#import "CHLogic.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHLogicDelegate <CHCommonLogicDelegate>
@optional
- (void)logicChannelUpdated:(NSString *)cid;
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids;
- (void)logicMessagesUnreadChanged:(NSNumber *)unread;
@end

@interface CHLogic : CHCommonLogic<id<CHLogicDelegate>>

@property (class, nonatomic, readonly, strong) CHLogic *shared;

// Read & Unread
- (NSInteger)unreadSumAllChannel;
- (NSInteger)unreadWithChannel:(nullable NSString *)cid;
- (void)addReadChannel:(nullable NSString *)cid;
- (void)removeReadChannel:(nullable NSString *)cid;


@end

NS_ASSUME_NONNULL_END
