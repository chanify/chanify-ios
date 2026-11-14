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
#import "CHNSDataSource.h"
#import "CHNotification.h"
#import "CHNodeModel.h"
#import "CHDevice.h"
#import "CHTP.pbobjc.h"

@interface CHLogic () <WCSessionDelegate, CHNotificationMessageDelegate>

@property (nonatomic, readonly, strong) WCSession *watchSession;
@property (nonatomic, readwrite) CHWatchConfigurationStatus configurationStatus;
@property (nonatomic, nullable, readwrite, strong) NSDate *lastConfigurationDate;
@property (nonatomic, readwrite) BOOL processingInbox;
@property (nonatomic, readwrite) BOOL inboxHasPendingMessages;
@property (nonatomic, nullable, readwrite, copy) NSString *pendingMessageID;
@property (nonatomic) NSUInteger inboxGeneration;
@property (nonatomic) BOOL inboxRefreshRequested;
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

- (void)active {
    [super active];
    [self refreshWatchMessages];
}

- (void)deactive {
    self.inboxGeneration++;
    self.processingInbox = NO;
    self.inboxRefreshRequested = NO;
    [super deactive];
}

- (void)updateUserModel:(CHUserModel *)me {
    self.inboxGeneration++;
    self.processingInbox = NO;
    self.inboxHasPendingMessages = NO;
    self.inboxRefreshRequested = NO;
    self.pendingMessageID = nil;
    [super updateUserModel:me];
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo {
    if (!NSThread.isMainThread) {
        dispatch_main_async(^{ [self receiveRemoteNotification:userInfo]; });
        return;
    }
    NSString *mid = nil;
    NSData *data = nil;
    NSString *uid = [CHMessageModel parsePacket:userInfo mid:&mid data:&data];
    if (uid.length == 0 || ![uid isEqualToString:self.me.uid] || mid.length == 0 || data.length == 0) return;
    // Stage the encrypted packet first so a failed user-DB commit can be retried.
    [self.nsDataSource pushMessage:data mid:mid uid:uid flags:nil];
    [self refreshWatchMessages];
}

- (void)updatePushToken:(NSData *)pushToken {
    [super updatePushToken:pushToken];
}

- (void)doLogin:(CHUserModel *)user key:(NSData *)key {
    [super doLogin:user key:key];
    [self refreshWatchMessages];
}

- (void)doLogout {
    [super doLogout];
}

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
    if (error == nil && activationState == WCSessionActivationStateActivated) {
        dispatch_main_async(^{ [self updateContext:session]; });
    } else if (error != nil) {
        dispatch_main_async(^{ [self setConfigurationFailed]; });
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
    [self receiveRemoteNotification:notification.request.content.userInfo];
}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {
    if (!NSThread.isMainThread) {
        dispatch_main_async(^{ [self receiveNotificationResponse:response]; });
        return;
    }
    if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) return;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:response.notification.request.content.userInfo mid:&mid data:nil];
    if (mid.length == 0 || ![uid isEqualToString:self.me.uid]) return;
    self.pendingMessageID = mid;
    [self receiveRemoteNotification:response.notification.request.content.userInfo];
    [self sendNotifyWithSelector:@selector(logicWatchOpenMessage:) withObject:mid];
}

#pragma mark - Messages
- (void)consumePendingMessageID:(NSString *)mid {
    if ([self.pendingMessageID isEqualToString:mid]) self.pendingMessageID = nil;
}

- (void)refreshWatchMessages {
    if (!NSThread.isMainThread) {
        dispatch_main_async(^{ [self refreshWatchMessages]; });
        return;
    }
    if (self.me == nil || self.userDataSource == nil) return;
    if (self.processingInbox) {
        self.inboxRefreshRequested = YES;
        return;
    }
    self.processingInbox = YES;
    self.inboxHasPendingMessages = NO;
    NSUInteger generation = ++self.inboxGeneration;
    NSString *uid = self.me.uid;
    CHUserDataSource *dataSource = self.userDataSource;
    [self sendNotifyWithSelector:@selector(logicWatchMessagesChanged)];
    dispatch_main_async(^{
        [self repairWatchCacheAfterMID:@"" uid:uid dataSource:dataSource generation:generation];
    });
}

- (void)repairWatchCacheAfterMID:(NSString *)cursor uid:(NSString *)uid dataSource:(CHUserDataSource *)dataSource generation:(NSUInteger)generation {
    if (generation != self.inboxGeneration || ![uid isEqualToString:self.me.uid] || dataSource != self.userDataSource) return;
    BOOL pending = self.inboxHasPendingMessages;
    NSError *error = nil;
    NSString *last = [dataSource repairWatchMessagesAfterMID:cursor storage:self.nsDataSource uid:uid limit:16 pending:&pending error:&error];
    self.inboxHasPendingMessages = pending;
    if (last.length > 0 && ![last isEqualToString:cursor] && error == nil) {
        dispatch_main_async(^{
            [self repairWatchCacheAfterMID:last uid:uid dataSource:dataSource generation:generation];
        });
    } else {
        [self drainWatchInboxAfterMID:@"" uid:uid dataSource:dataSource generation:generation];
    }
}

- (void)drainWatchInboxAfterMID:(NSString *)cursor uid:(NSString *)uid dataSource:(CHUserDataSource *)dataSource generation:(NSUInteger)generation {
    if (generation != self.inboxGeneration || ![uid isEqualToString:self.me.uid] || dataSource != self.userDataSource) return;
    NSMutableArray<NSString *> *committed = [NSMutableArray new];
    // Yield to the run loop between batches. Failed packets are skipped for this
    // pass, retained in the inbox, and retried on the next explicit refresh.
    NSError *error = nil;
    NSString *last = [self.nsDataSource enumerateWatchMessagesWithUID:uid afterMID:cursor limit:16 error:&error block:^(FMDatabase *db, NSString *mid, NSData *data) {
        CHUpsertMessageFlags flags = 0;
        CHMessageModel *message = [dataSource upsertMessageData:data nsDB:[CHTempNSDatasource datasourceFromDB:db] uid:uid mid:mid checker:nil flags:&flags];
        if (message != nil || (flags & CHUpsertMessageFlagDiscarded)) {
            [committed addObject:mid];
        } else {
            self.inboxHasPendingMessages = YES;
        }
    }];
    if (error != nil) self.inboxHasPendingMessages = YES;
    if (committed.count > 0) [self.nsDataSource removeMessages:committed uid:uid];
    [self sendNotifyWithSelector:@selector(logicWatchMessagesChanged)];
    if (last.length > 0 && ![last isEqualToString:cursor]) {
        dispatch_main_async(^{
            [self drainWatchInboxAfterMID:last uid:uid dataSource:dataSource generation:generation];
        });
    } else {
        self.processingInbox = NO;
        [self sendNotifyWithSelector:@selector(logicWatchMessagesChanged)];
        if (self.inboxRefreshRequested) {
            self.inboxRefreshRequested = NO;
            [self refreshWatchMessages];
        }
    }
}

#pragma mark - Private Methods
- (void)setConfigurationFailed {
    self.configurationStatus = CHWatchConfigurationStatusFailed;
    [self sendNotifyWithSelector:@selector(logicWatchConfigurationChanged)];
}

- (void)retryWatchConfiguration {
    [self updateContext:self.watchSession];
}

- (void)updateContext:(WCSession *)session {
    NSData *data = [session.receivedApplicationContext objectForKey:@"data"];
    // No context yet is different from an explicit empty account configuration.
    if (data == nil) return;
    if (![data isKindOfClass:NSData.class]) {
        [self setConfigurationFailed];
        return;
    }
    NSError *error = nil;
    CHUserModel *me = nil;
    CHTPWatchConfig *cfg = [CHTPWatchConfig parseFromData:data error:&error];
    if (error != nil || cfg == nil) {
        [self setConfigurationFailed];
        return;
    }
    if (error == nil) {
        me = [CHUserModel modelWithKey:[CHSecKey secKeyWithData:cfg.userKey]];
    }
    if (cfg.userKey.length > 0 && me == nil) {
        [self setConfigurationFailed];
        return;
    }
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
            if (![self deleteLocalAccountWithUID:uid]) {
                [self setConfigurationFailed];
                return;
            }
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
    self.lastConfigurationDate = NSDate.date;
    self.configurationStatus = CHWatchConfigurationStatusReceived;
    [self sendNotifyWithSelector:@selector(logicWatchConfigurationChanged)];
    [self refreshWatchMessages];
}

// The phone owns node configuration. Refresh metadata without allowing an old
// request to restore a removed node or update a different account's node.
- (void)updateNodeInfo:(NSString *)nid completion:(CHLogicBlock)completion {
    CHNodeModel *node = [self.userDataSource nodeWithNID:nid];
    if (node == nil || node.isSystem || self.me == nil) {
        if (completion != nil) completion(CHLCodeFailed);
        return;
    }
    NSString *accountID = self.me.uid;
    NSUInteger generation = self.nodeSyncGeneration;
    @weakify(self);
    [self loadNodeWitEndpoint:node.endpoint completion:^(CHLCode result, NSDictionary *data) {
        @strongify(self);
        CHNodeModel *current = [self.userDataSource nodeWithNID:nid];
        CHNodeModel *response = result == CHLCodeOK ? [CHNodeModel modelWithNSDictionary:data] : nil;
        BOOL valid = self != nil && [self.me.uid isEqualToString:accountID] &&
            generation == self.nodeSyncGeneration && current != nil &&
            [self.syncedNodeIDs containsObject:nid] && [current isEqual:node] &&
            [current.version isEqualToString:node.version] && [current.pubkey isEqualToData:node.pubkey] &&
            [response.nid isEqualToString:nid] && [response.pubkey isEqualToData:current.pubkey];
        CHLCode code = CHLCodeFailed;
        if (valid) {
            CHNodeModel *updated = [CHNodeModel modelWithNID:nid name:current.name version:response.version endpoint:current.endpoint pubkey:current.pubkey flags:current.flags features:[response.features componentsJoinedByString:@","]];
            updated.icon = current.icon;
            if ([self updateNode:updated]) code = CHLCodeOK;
        }
        if (completion != nil) completion(code);
    }];
}

// Check again at the actual database write, after the bind request returns.
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret {
    if (![self.syncedNodeIDs containsObject:model.nid]) return NO;
    NSNumber *generation = [self.nodeBindGenerations objectForKey:model];
    if (generation != nil && generation.unsignedIntegerValue != self.nodeSyncGeneration) return NO;
    BOOL inserted = [super insertNode:model secret:secret];
    if (inserted) {
        NSString *uid = self.me.uid;
        NSString *nid = model.nid;
        NSUInteger syncGeneration = self.nodeSyncGeneration;
        @weakify(self);
        // The base bind copies the key to the notification store after this
        // method returns. Defer retry to cover both sync and account rebinds.
        dispatch_main_async(^{
            @strongify(self);
            if (syncGeneration == self.nodeSyncGeneration && [self.me.uid isEqualToString:uid] && [self.syncedNodeIDs containsObject:nid]) {
                [self refreshWatchMessages];
            }
        });
    }
    return inserted;
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
        NSData *secret = [self.userDataSource keyForNodeID:node.nid];
        BOOL bound = existing != nil && secret.length > 0;
        BOOL bindingChanged = ![existing.endpoint isEqualToString:node.endpoint] ||
            ![existing.pubkey isEqualToData:node.pubkey] || existing.flags != node.flags;
        if (bound && !bindingChanged) {
            // A previous process can stop between committing the node and copying
            // its key to the notification store. Restore that copy without rebinding.
            NSString *keyID = [NSString stringWithFormat:@"%@.%@", self.me.uid, node.nid];
            if (secret.length >= 64 && ![[self.nsDataSource keyForUID:keyID] isEqualToData:secret]) {
                [self.nsDataSource updateKey:secret uid:keyID];
                [self refreshWatchMessages];
            }
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
