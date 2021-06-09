//
//  CHLogic+iOS.h
//  Chanify
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHLogic : CHAppLogic

+ (instancetype)shared;

// API
- (void)createAccountWithCompletion:(nullable CHLogicBlock)completion;
// Nodes
- (void)reconnectNode:(nullable NSString *)nid completion:(nullable CHLogicBlock)completion;
// Blocklist
- (void)upsertBlockedToken:(NSString *)token;
- (void)removeBlockedTokens:(NSArray<NSString *> *)tokens;
- (NSArray<NSString *> *)blockedTokens;
// Watch
- (BOOL)hasWatch;
- (BOOL)isWatchAppInstalled;
- (BOOL)syncDataToWatch:(BOOL)focus;


@end

NS_ASSUME_NONNULL_END
