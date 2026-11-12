//
//  CHLogic+watchOS.m
//  Watch Extension
//
//  Created by WizJin on 2021/4/21.
//

#import "CHLogic+watchOS.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <UserNotifications/UserNotifications.h>
#import <WatchKit/WatchKit.h>
#import "CHUserDataSource.h"
#import "CHNotification.h"
#import "CHNodeModel.h"
#import "CHDevice.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate, CHNotificationMessageDelegate>

@property (nonatomic, readonly, strong) WCSession *watchSession;
@property (nonatomic, copy) NSSet<NSString *> *syncedNodeIDs;
@property (nonatomic) NSUInteger nodeSyncGeneration;
@property (nonatomic, strong) NSMapTable<CHNodeModel *, NSNumber *> *nodeBindGenerations;
- (void)unbindNode:(CHNodeModel *)node;

@end

@implementation CHLogic

+ (instancetype)shared {
    static CHLogic *logic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logic = [CHLogic new];
    });
    return logic;
}

- (instancetype)init {
    if (self = [super initWithAppGroup:@kCHAppWatchGroupName]) {
        if (!WCSession.isSupported) {
            _watchSession = nil;
        } else {
            _watchSession = WCSession.defaultSession;
            self.watchSession.delegate = self;
        }
        CHNotification.shared.delegate = self;
    }
    return self;
}

- (void)launch {
    [super launch];
    [self.watchSession activateSession];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
}

- (void)updatePushToken:(NSData *)pushToken {
    [super updatePushToken:pushToken];
}

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [super doLogin:user key:key];
}

- (void)doLogout {
    [super doLogout];
}

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
    if (error == nil && activationState == WCSessionActivationStateActivated) {
        dispatch_main_async(^{ [self updateContext:session]; });
    }
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        [self updateContext:session];
    });
}

#pragma mark - CHNotificationMessageDelegate
- (void)registerForRemoteNotifications {
    dispatch_main_async(^{
        [WKExtension.sharedExtension registerForRemoteNotifications];
    });
}

- (void)receiveNotification:(UNNotification *)notification {

}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {

}

#pragma mark - Private Methods
- (void)updateContext:(WCSession *)session {
    NSData *data = [session.receivedApplicationContext objectForKey:@"data"];
    // No context yet is different from an explicit empty account configuration.
    if (![data isKindOfClass:NSData.class]) return;
    NSError *error = nil;
    CHUserModel *me = nil;
    CHTPWatchConfig *cfg = [CHTPWatchConfig parseFromData:data error:&error];
    if (error != nil || cfg == nil) return;
    if (error == nil) {
        me = [CHUserModel modelWithKey:[CHSecKey secKeyWithData:cfg.userKey]];
    }
    if (cfg.userKey.length > 0 && me == nil) return;
    NSMutableSet<NSString *> *nodeIDs = [NSMutableSet new];
    for (CHTPNode *node in cfg.nodesArray) [nodeIDs addObject:node.nid];
    self.syncedNodeIDs = nodeIDs;
    self.nodeSyncGeneration++;
    // Apply historical deletions even after switching to another account.
    // An explicitly re-imported account in the current configuration wins.
    id deletedAccounts = session.receivedApplicationContext[@"deletedAccounts"];
    if ([deletedAccounts isKindOfClass:NSArray.class]) {
        for (id uid in deletedAccounts) {
            if (![uid isKindOfClass:NSString.class] || [uid length] == 0 || [uid isEqualToString:me.uid]) continue;
            if (![[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"] isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:uid]]) continue;
            if (![self deleteLocalAccountWithUID:uid]) return;
        }
    }
    BOOL updated = NO;
    if (self.me == nil || ![self.me.uid isEqualToString:me.uid]) {
        if (self.me != nil) {
            // Replace local state synchronously. An old asynchronous unbind must not
            // clear the newly imported account or unbind it on the server.
            [self doLogout];
        }
        
        [self updateUserModel:me];
        [self reloadUserDB:NO];
        
        updated = YES;
    }
    if (self.me != nil) {
        if (self.userDataSource.srvkey.length == 0) {
            [self importAccount:self.me.key.seckey.base64Code completion:nil];
        }
        for (CHNodeModel *node in self.userDataSource.loadNodes) {
            if (!node.isSystem && ![nodeIDs containsObject:node.nid]) [self deleteNode:node.nid];
        }
        for (CHTPNode *node in cfg.nodesArray) {
            [self bindNode:node];
        }
        NSMutableSet<NSString *> *blocks = [NSMutableSet new];
        for (CHTPBlockItem *item in cfg.blocklistArray) {
            if (item.token.length > 0) {
                [blocks addObject:item.token];
            }
        }
        NSMutableArray<NSString *> *removedItems = [NSMutableArray new];
        for (NSString *token in self.blockedTokens) {
            if ([blocks containsObject:token]) {
                [blocks removeObject:token];
            } else {
                [removedItems addObject:token];
            }
        }
        if (removedItems.count > 0) {
            [self removeBlockedTokens:removedItems];
        }
        if (blocks.count > 0) {
            for (NSString *token in blocks) {
                [self upsertBlockedToken:token];
            }
        }
    }
    if (updated) {
        [self sendNotifyWithSelector:@selector(logicUserInfoChanged:) withObject:me];
    }
}

// Check again at the actual database write, after the bind request returns.
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret {
    if (![self.syncedNodeIDs containsObject:model.nid]) return NO;
    NSNumber *generation = [self.nodeBindGenerations objectForKey:model];
    if (generation != nil && generation.unsignedIntegerValue != self.nodeSyncGeneration) return NO;
    return [super insertNode:model secret:secret];
}

- (BOOL)deleteNode:(NSString *)nid {
    if (nid.length == 0) return NO;
    // A local deletion must also cancel writes already in flight for this node.
    NSMutableSet *nodeIDs = [self.syncedNodeIDs mutableCopy];
    [nodeIDs removeObject:nid];
    self.syncedNodeIDs = nodeIDs;
    return [super deleteNode:nid];
}

- (void)bindNode:(CHTPNode *)node {
    if (node.nid.length > 0 && ![node.nid isEqualToString:@"sys"]) {
        CHNodeModel *existing = [self.userDataSource nodeWithNID:node.nid];
        // A deleted row can retain a decryption key. Only an active node is bound.
        BOOL bound = existing != nil && [self.userDataSource keyForNodeID:node.nid].length > 0;
        BOOL bindingChanged = ![existing.endpoint isEqualToString:node.endpoint] ||
            ![existing.pubkey isEqualToData:node.pubkey] || existing.flags != node.flags;
        if (bound && !bindingChanged) {
            CHNodeModel *updated = [CHNodeModel modelWithNID:node.nid name:node.name version:node.version endpoint:node.endpoint pubkey:node.pubkey flags:(CHNodeModelFlags)node.flags features:[existing.features componentsJoinedByString:@","]];
            updated.icon = node.icon;
            if (![existing isEqual:updated] || ![existing.version isEqualToString:updated.version]) [self updateNode:updated];
        } else {
            NSString *accountID = self.me.uid;
            NSUInteger generation = self.nodeSyncGeneration;
            @weakify(self);
            [self loadNodeWitEndpoint:node.endpoint completion:^(CHLCode result, NSDictionary *data) {
                @strongify(self);
                if (result == CHLCodeOK && generation == self.nodeSyncGeneration && [self.me.uid isEqualToString:accountID] && [self.syncedNodeIDs containsObject:node.nid]) {
                    CHNodeModel *model = [CHNodeModel modelWithNSDictionary:data];
                    if ([model.nid isEqualToString:node.nid] && [model.pubkey isEqualToData:node.pubkey]) {
                        model = [CHNodeModel modelWithNID:node.nid name:node.name version:model.version endpoint:node.endpoint pubkey:model.pubkey flags:(CHNodeModelFlags)node.flags features:[model.features componentsJoinedByString:@","]];
                        model.icon = node.icon;
                        if (self.nodeBindGenerations == nil) self.nodeBindGenerations = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsStrongMemory];
                        [self.nodeBindGenerations setObject:@(generation) forKey:model];
                        [self insertNode:model completion:^(CHLCode result) {
                            @strongify(self);
                            if (result != CHLCodeOK || generation != self.nodeSyncGeneration || ![self.me.uid isEqualToString:accountID]) return;
                            if (existing.isStoreDevice && !model.isStoreDevice) [self unbindNode:existing];
                            if (result == CHLCodeOK && model.isStoreDevice) {
                                [self updatePushToken:CHNotification.shared.pushToken node:[self nodeModelWithNID:model.nid] completion:nil];
                            }
                        }];
                    }
                }
            }];
        }
    }
}


@end
