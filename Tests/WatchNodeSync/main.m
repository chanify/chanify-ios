#import "CHLogic+watchOS.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHNodeModel.h"
#import "CHNotification.h"
#import "CHTP.pbobjc.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <WatchKit/WatchKit.h>
#import <UserNotifications/UserNotifications.h>

static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}
@implementation UNNotificationContent @end
@implementation UNNotificationRequest @end
@implementation UNNotification @end
@implementation UNNotificationResponse @end
@implementation CHTPNode @end
@implementation CHTPBlockItem @end
static CHTPWatchConfig *parsedConfiguration;
@implementation CHTPWatchConfig
+ (instancetype)parseFromData:(NSData *)data error:(NSError **)error { return parsedConfiguration; }
@end
@implementation WCSession
+ (BOOL)isSupported { return NO; }
+ (instancetype)defaultSession { return nil; }
- (void)activateSession {}
@end
@implementation WKExtension
+ (instancetype)sharedExtension { return nil; }
- (void)registerForRemoteNotifications {}
@end
@implementation CHManager
- (void)sendNotifyWithSelector:(SEL)action {}
- (void)sendNotifyWithSelector:(SEL)action withObject:(id)object {}
@end
@implementation CHMessageModel
+ (NSString *)parsePacket:(NSDictionary *)info mid:(NSString **)mid data:(NSData **)data {
    if (mid) *mid = info[@"mid"];
    if (data) *data = info[@"data"];
    return info[@"uid"];
}
@end
@implementation CHNSDataSource
- (NSData *)keyForUID:(NSString *)uid { return nil; }
- (BOOL)checkBlockedTokenWithKey:(NSString *)key uid:(NSString *)uid { return NO; }
@end
@implementation CHTempNSDatasource
- (NSData *)keyForUID:(NSString *)uid { return nil; }
- (BOOL)checkBlockedTokenWithKey:(NSString *)key uid:(NSString *)uid { return NO; }
+ (instancetype)datasourceFromDB:(FMDatabase *)db { return [self new]; }
@end
@implementation CHNotification
+ (instancetype)shared { return nil; }
@end
@implementation CHSecKey
+ (instancetype)secKeyWithData:(NSData *)data { return nil; }
+ (instancetype)secKeyWithPublicKeyData:(NSData *)data { return data.length ? [self new] : nil; }
- (NSString *)formatID:(uint8_t)code { return @"node"; }
@end
@implementation CHUserModel
+ (instancetype)modelWithKey:(CHSecKey *)key { return nil; }
- (NSString *)uid { return @"synthetic-user"; }
@end
@implementation NSData (TestEncoding)
+ (instancetype)dataFromBase64:(NSString *)text { return [[NSData alloc] initWithBase64EncodedString:text options:0]; }
- (NSString *)base64Code { return [self base64EncodedStringWithOptions:0]; }
@end
@implementation NSString (TestString)
- (NSString *)localized { return self; }
- (BOOL)compareAsVersion:(NSString *)other { return [self compare:other options:NSNumericSearch] == NSOrderedDescending; }
@end
@interface CHUserDataSource ()
@property (strong) NSMutableDictionary *testNodes, *testKeys;
@property (strong) NSMutableSet *testMessages, *testFailingMessages, *testDiscardedMessages;
@end
@implementation CHUserDataSource
- (instancetype)init { if ((self = [super init])) { _testNodes = [NSMutableDictionary new]; _testKeys = [NSMutableDictionary new]; _testMessages = [NSMutableSet new]; _testFailingMessages = [NSMutableSet new]; _testDiscardedMessages = [NSMutableSet new]; } return self; }
- (NSString *)repairWatchMessagesAfterMID:(NSString *)mid storage:(id)storage uid:(NSString *)uid limit:(NSUInteger)limit pending:(BOOL *)pending error:(NSError **)error { return nil; }
- (CHMessageModel *)upsertMessageData:(NSData *)data nsDB:(id)nsDB uid:(NSString *)uid mid:(NSString *)mid checker:(BOOL (NS_NOESCAPE ^)(NSString *))checker flags:(CHUpsertMessageFlags *)flags {
    check(NSThread.isMainThread, @"inbox writes stay serialized with account changes");
    check(checker == nil, @"Watch summary ingestion does not change unread counters");
    *flags = 0;
    if ([self.testFailingMessages containsObject:mid]) return nil;
    if ([self.testDiscardedMessages containsObject:mid]) { *flags = CHUpsertMessageFlagDiscarded; return nil; }
    [self.testMessages addObject:mid];
    return [CHMessageModel new];
}
- (CHNodeModel *)nodeWithNID:(NSString *)nid { return self.testNodes[nid]; }
- (NSData *)keyForNodeID:(NSString *)nid { return self.testKeys[nid]; }
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret { self.testNodes[model.nid] = model; self.testKeys[model.nid] = secret; return YES; }
- (BOOL)updateNode:(CHNodeModel *)model { self.testNodes[model.nid] = model; return YES; }
- (BOOL)deleteNode:(NSString *)nid { [self.testNodes removeObjectForKey:nid]; return YES; }
@end
@interface CHLogicBase ()
@property (readwrite, strong) CHUserModel *me;
@property (readwrite, strong) CHNSDataSource *nsDataSource;
@property (readwrite, strong) CHUserDataSource *userDataSource;
@end
@implementation CHLogicBase
- (void)updateUserModel:(CHUserModel *)me { self.me = me; }
- (void)reloadUserDB:(BOOL)force {}
- (instancetype)initWithAppGroup:(NSString *)group { if ((self = [super init])) { _me = [CHUserModel new]; _userDataSource = [CHUserDataSource new]; } return self; }
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret { return [self.userDataSource insertNode:model secret:secret]; }
- (BOOL)updateNode:(CHNodeModel *)model { return [self.userDataSource updateNode:model]; }
- (CHNodeModel *)nodeModelWithNID:(NSString *)nid { return [self.userDataSource nodeWithNID:nid]; }
- (BOOL)deleteNode:(NSString *)nid { return [self.userDataSource deleteNode:nid]; }
@end
@interface CHLogic (TestAccess)
- (void)bindNode:(CHTPNode *)node;
- (void)receiveNotificationResponse:(UNNotificationResponse *)response;
- (void)updateContext:(WCSession *)session;
- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)state error:(NSError *)error;
@end
@interface TestLogic : CHLogic
@property (strong) NSMutableArray *loads, *binds;
@property NSUInteger unbinds, pushUpdates, watchRefreshes;
@property BOOL refreshSawNodeKey;
@end
@implementation TestLogic
- (instancetype)init { if ((self = [super init])) { _loads = [NSMutableArray new]; _binds = [NSMutableArray new]; } return self; }
- (void)refreshWatchMessages {
    self.watchRefreshes++;
    if ([self.nsDataSource keyForUID:[NSString stringWithFormat:@"%@.node", self.me.uid]].length == 64) self.refreshSawNodeKey = YES;
    [super refreshWatchMessages];
}
- (void)loadNodeWitEndpoint:(NSString *)endpoint completion:(CHLogicResultBlock)completion { [self.loads addObject:[completion copy]]; }
- (void)insertNode:(CHNodeModel *)model completion:(CHLogicBlock)completion {
    __weak typeof(self) weakSelf = self;
    [self.binds addObject:[^{ BOOL ok = [weakSelf insertNode:model secret:[@"secret" dataUsingEncoding:NSUTF8StringEncoding]]; completion(ok ? CHLCodeOK : CHLCodeFailed); } copy]];
}
- (void)unbindNode:(CHNodeModel *)node { self.unbinds++; }
- (void)updatePushToken:(NSData *)token node:(CHNodeModel *)node completion:(CHLogicBlock)completion { self.pushUpdates++; }
@end
@interface TestInbox : CHNSDataSource
@property (strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *accounts;
@property NSUInteger maxBatch;
@property (strong) NSMutableDictionary *keys;
@end
@implementation TestInbox
- (instancetype)init { if ((self = [super init])) { _accounts = [NSMutableDictionary new]; _keys = [NSMutableDictionary new]; } return self; }
- (NSData *)keyForUID:(NSString *)uid { return self.keys[uid]; }
- (void)updateKey:(NSData *)key uid:(NSString *)uid { if (key) self.keys[uid] = key; else [self.keys removeObjectForKey:uid]; }
- (CHMessageModel *)pushMessage:(NSData *)data mid:(NSString *)mid uid:(NSString *)uid flags:(CHMessageProcessFlags *)flags {
    if (!self.accounts[uid]) self.accounts[uid] = [NSMutableDictionary new];
    if (!self.accounts[uid][mid]) self.accounts[uid][mid] = data;
    return nil;
}
- (NSString *)enumerateWatchMessagesWithUID:(NSString *)uid afterMID:(NSString *)mid limit:(NSUInteger)limit error:(NSError **)error block:(void (NS_NOESCAPE ^)(FMDatabase *, NSString *, NSData *))block {
    NSArray *keys = [self.accounts[uid].allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSUInteger count = 0;
    NSString *last = nil;
    for (NSString *key in keys) {
        if ([key compare:mid] != NSOrderedDescending) continue;
        if (count++ == limit) break;
        last = key;
        block(nil, key, self.accounts[uid][key]);
    }
    self.maxBatch = MAX(self.maxBatch, MIN(count, limit));
    return last;
}
- (void)removeMessages:(NSArray *)mids uid:(NSString *)uid { [self.accounts[uid] removeObjectsForKeys:mids]; }
@end
static void finishInbox(CHLogic *logic) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:1];
    while (logic.processingInbox && deadline.timeIntervalSinceNow > 0) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }
    check(!logic.processingInbox, @"inbox pass terminates even when failed messages remain");
}
static NSDictionary *info(NSString *nid) {
    return @{@"nodeid": nid, @"pubkey": @"a2V5", @"version": @"2", @"name": @"Server", @"endpoint": @"https://invalid.example", @"features": @[@"platform.watchos"]};
}
static void finishLoad(TestLogic *logic, NSUInteger index, NSDictionary *data) { ((CHLogicResultBlock)logic.loads[index])(CHLCodeOK, data); }
static void finishBind(TestLogic *logic, NSUInteger index) { ((void (^)(void))logic.binds[index])(); }
int main(void) { @autoreleasepool {
    TestLogic *logic = [TestLogic new];
    check(![logic deleteNode:nil] && ![logic deleteNode:@""], @"invalid node deletion fails safely");
    [logic setValue:[NSSet setWithObject:@"node"] forKey:@"syncedNodeIDs"];
    [logic setValue:@1 forKey:@"nodeSyncGeneration"];
    CHTPNode *cfg = [CHTPNode new]; cfg.nid = @"node"; cfg.name = @"Phone name"; cfg.version = @"2";
    cfg.endpoint = @"https://invalid.example"; cfg.pubkey = [@"key" dataUsingEncoding:NSUTF8StringEncoding]; cfg.icon = @"new-icon";
    [logic bindNode:cfg]; check(logic.loads.count == 1, @"new node loads server info");
    finishLoad(logic, 0, info(@"node")); finishBind(logic, 0);
    check([[logic.userDataSource nodeWithNID:@"node"].name isEqual:cfg.name], @"phone name wins over server name");
    cfg.name = @"Renamed"; cfg.icon = @"changed"; cfg.version = @"3";
    [logic bindNode:cfg]; CHNodeModel *updated = [logic.userDataSource nodeWithNID:@"node"];
    check([updated.name isEqual:cfg.name] && [updated.icon isEqual:cfg.icon] && [updated.version isEqual:cfg.version] && logic.loads.count == 1, @"bound node metadata updates without network");
    [logic.userDataSource deleteNode:@"node"];
    check([logic.userDataSource keyForNodeID:@"node"].length > 0, @"deleted fixture retains key");
    [logic bindNode:cfg]; check(logic.loads.count == 2, @"re-add rebinds despite retained key");
    finishLoad(logic, 1, info(@"node")); finishBind(logic, 1);
    check([logic.userDataSource nodeWithNID:@"node"] != nil, @"re-add restores active node");
    cfg.flags = 1; [logic bindNode:cfg]; finishLoad(logic, 2, info(@"node")); finishBind(logic, 2);
    check([logic.userDataSource nodeWithNID:@"node"].isStoreDevice && logic.pushUpdates == 1, @"enable device binding updates push token");
    cfg.flags = 0; [logic bindNode:cfg]; finishLoad(logic, 3, info(@"node")); finishBind(logic, 3);
    check(![logic.userDataSource nodeWithNID:@"node"].isStoreDevice && logic.unbinds == 1, @"disable device binding unregisters old device");
    cfg.endpoint = @"https://new.invalid.example"; [logic bindNode:cfg];
    [logic setValue:@2 forKey:@"nodeSyncGeneration"]; finishLoad(logic, 4, info(@"node"));
    check(logic.binds.count == 4, @"stale info response cannot initiate binding");
    [logic bindNode:cfg]; finishLoad(logic, 5, info(@"node"));
    [logic setValue:@3 forKey:@"nodeSyncGeneration"]; finishBind(logic, 4);
    check([[logic.userDataSource nodeWithNID:@"node"].endpoint isEqual:@"https://invalid.example"], @"stale bind response cannot overwrite current configuration");
    [logic bindNode:cfg]; finishLoad(logic, 6, info(@"different-node"));
    check(logic.binds.count == 5, @"mismatched node identity is rejected");
    [logic bindNode:cfg]; finishLoad(logic, 7, info(@"node"));
    [logic setValue:@4 forKey:@"nodeSyncGeneration"];
    [logic bindNode:cfg]; finishLoad(logic, 8, info(@"node"));
    finishBind(logic, 5);
    check([[logic.userDataSource nodeWithNID:@"node"].endpoint isEqual:@"https://invalid.example"], @"equal model objects retain independent request generations");
    finishBind(logic, 6);
    check([[logic.userDataSource nodeWithNID:@"node"].endpoint isEqual:cfg.endpoint], @"latest generation succeeds");
    cfg.endpoint = @"https://third.invalid.example"; [logic bindNode:cfg]; finishLoad(logic, 9, info(@"node"));
    [logic deleteNode:@"node"]; finishBind(logic, 7);
    check([logic.userDataSource nodeWithNID:@"node"] == nil, @"local deletion cancels pending bind");
    for (id malformed in @[@[], @"text", NSNull.null, @{@"nodeid": @7}, @{@"nodeid": @"node", @"version": NSNull.null}, @{@"features": @[@1]}, @{@"features": @"bad"}]) {
        check([CHNodeModel modelWithNSDictionary:malformed] == nil, @"malformed node JSON is rejected without exception");
    }
    TestLogic *refreshLogic = [TestLogic new];
    [refreshLogic setValue:[NSSet setWithObject:@"node"] forKey:@"syncedNodeIDs"];
    [refreshLogic setValue:@1 forKey:@"nodeSyncGeneration"];
    CHNodeModel *refreshNode = [CHNodeModel modelWithNID:@"node" name:@"Phone name" version:@"1" endpoint:@"https://phone.invalid.example" pubkey:[@"key" dataUsingEncoding:NSUTF8StringEncoding] flags:1 features:@"platform.watchos"];
    refreshNode.icon = @"phone-icon";
    [refreshLogic.userDataSource insertNode:refreshNode secret:[NSData data]];
    __block CHLCode refreshResult = CHLCodeFailed;
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    finishLoad(refreshLogic, 0, info(@"node"));
    CHNodeModel *refreshed = [refreshLogic.userDataSource nodeWithNID:@"node"];
    check(refreshResult == CHLCodeOK && [refreshed.version isEqual:@"2"] && [refreshed.name isEqual:@"Phone name"] && [refreshed.endpoint isEqual:refreshNode.endpoint] && [refreshed.icon isEqual:@"phone-icon"] && refreshed.flags == 1, @"manual refresh updates metadata and preserves phone-owned configuration");
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    [refreshLogic setValue:@2 forKey:@"nodeSyncGeneration"];
    finishLoad(refreshLogic, 1, info(@"node"));
    check(refreshResult == CHLCodeFailed, @"configuration changes invalidate manual refresh");
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    [refreshLogic deleteNode:@"node"];
    finishLoad(refreshLogic, 2, info(@"node"));
    check(refreshResult == CHLCodeFailed && [refreshLogic.userDataSource nodeWithNID:@"node"] == nil, @"manual refresh cannot restore a deleted node");
    [refreshLogic.userDataSource insertNode:refreshed secret:[NSData data]];
    [refreshLogic setValue:[NSSet setWithObject:@"node"] forKey:@"syncedNodeIDs"];
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    [refreshLogic setValue:nil forKey:@"me"];
    finishLoad(refreshLogic, 3, info(@"node"));
    check(refreshResult == CHLCodeFailed, @"account changes invalidate manual refresh");
    [refreshLogic setValue:[CHUserModel new] forKey:@"me"];
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    finishLoad(refreshLogic, 4, @{@"nodeid": @7});
    check(refreshResult == CHLCodeFailed, @"manual refresh rejects malformed node response");
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    NSMutableDictionary *wrongKey = [info(@"node") mutableCopy];
    wrongKey[@"pubkey"] = @"b3RoZXI=";
    finishLoad(refreshLogic, 5, wrongKey);
    check(refreshResult == CHLCodeFailed && [refreshed.pubkey isEqual:[refreshLogic.userDataSource nodeWithNID:@"node"].pubkey], @"manual refresh cannot replace the phone-owned public key");
    [refreshLogic updateNodeInfo:@"node" completion:^(CHLCode code) { refreshResult = code; }];
    ((CHLogicResultBlock)refreshLogic.loads[6])(CHLCodeFailed, @{});
    check(refreshResult == CHLCodeFailed, @"manual refresh reports network failures");
    NSUInteger requests = refreshLogic.loads.count;
    [refreshLogic updateNodeInfo:@"missing" completion:^(CHLCode code) { refreshResult = code; }];
    check(refreshResult == CHLCodeFailed && refreshLogic.loads.count == requests, @"missing node fails without network access");
    puts("PASS: Watch manual refresh metadata, generation, deletion, account and identity guards");
    TestLogic *keyLogic = [TestLogic new];
    TestInbox *keyInbox = [TestInbox new];
    [keyLogic setValue:keyInbox forKey:@"nsDataSource"];
    NSData *storedKey = [NSMutableData dataWithLength:64];
    [keyLogic.userDataSource insertNode:refreshNode secret:storedKey];
    CHTPNode *keyConfig = [CHTPNode new];
    keyConfig.nid = refreshNode.nid; keyConfig.endpoint = refreshNode.endpoint; keyConfig.pubkey = refreshNode.pubkey;
    keyConfig.name = refreshNode.name; keyConfig.flags = refreshNode.flags; keyConfig.version = refreshNode.version;
    [keyLogic bindNode:keyConfig]; finishInbox(keyLogic);
    check([[keyInbox keyForUID:[NSString stringWithFormat:@"%@.%@", keyLogic.me.uid, refreshNode.nid]] isEqual:storedKey] && keyLogic.loads.count == 0, @"bound node repairs a missing notification key without a network request");
    TestLogic *insertLogic = [TestLogic new];
    TestInbox *insertInbox = [TestInbox new];
    [insertLogic setValue:insertInbox forKey:@"nsDataSource"];
    [insertLogic setValue:[NSSet setWithObject:@"node"] forKey:@"syncedNodeIDs"];
    check([insertLogic insertNode:refreshNode secret:storedKey], @"node insertion succeeds before the base bind copies its key");
    check(insertLogic.watchRefreshes == 0, @"message retry is deferred until the bind can copy its key");
    [insertInbox updateKey:storedKey uid:[NSString stringWithFormat:@"%@.node", insertLogic.me.uid]];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    finishInbox(insertLogic);
    check(insertLogic.watchRefreshes == 1 && insertLogic.refreshSawNodeKey, @"all successful node insertions retry after the decryption key is installed");
    TestLogic *messageLogic = [TestLogic new];
    TestInbox *inbox = [TestInbox new];
    [messageLogic setValue:inbox forKey:@"nsDataSource"];
    for (NSUInteger i = 1; i <= 35; i++) {
        [inbox pushMessage:[NSData dataWithBytes:"x" length:1] mid:[NSString stringWithFormat:@"%016lx", (unsigned long)i] uid:messageLogic.me.uid flags:nil];
    }
    [inbox pushMessage:[NSData dataWithBytes:"x" length:1] mid:@"other" uid:@"other-account" flags:nil];
    [messageLogic.userDataSource.testFailingMessages addObject:@"0000000000000002"];
    [messageLogic.userDataSource.testDiscardedMessages addObject:@"0000000000000003"];
    [messageLogic refreshWatchMessages]; finishInbox(messageLogic);
    check(inbox.maxBatch <= 16 && messageLogic.userDataSource.testMessages.count == 33, @"bounded ingestion spans multiple batches");
    check(inbox.accounts[messageLogic.me.uid].count == 1 && inbox.accounts[@"other-account"].count == 1 && messageLogic.inboxHasPendingMessages, @"only committed or explicitly discarded messages leave the correct account inbox");
    [messageLogic.userDataSource.testFailingMessages removeAllObjects];
    [messageLogic refreshWatchMessages]; finishInbox(messageLogic);
    check(inbox.accounts[messageLogic.me.uid].count == 0 && messageLogic.userDataSource.testMessages.count == 34 && !messageLogic.inboxHasPendingMessages, @"recoverable failures succeed on the next refresh");
    [messageLogic receiveRemoteNotification:@{@"uid": messageLogic.me.uid, @"mid": @"0000000000000001", @"data": [NSData dataWithBytes:"x" length:1]}];
    finishInbox(messageLogic);
    check(messageLogic.userDataSource.testMessages.count == 34, @"duplicate delivery does not duplicate a message");
    [messageLogic receiveRemoteNotification:@{@"uid": @"other-account", @"mid": @"wrong", @"data": [NSData dataWithBytes:"x" length:1]}];
    check(inbox.accounts[@"other-account"].count == 1 && !messageLogic.processingInbox, @"packets for other accounts do not start processing");
    NSString *messageUID = messageLogic.me.uid;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [messageLogic receiveRemoteNotification:@{@"uid": messageUID, @"mid": @"background", @"data": [NSData dataWithBytes:"x" length:1]}];
    });
    NSDate *messageDeadline = [NSDate dateWithTimeIntervalSinceNow:1];
    while (messageLogic.userDataSource.testMessages.count < 35 && messageDeadline.timeIntervalSinceNow > 0) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }
    finishInbox(messageLogic);
    check(messageLogic.userDataSource.testMessages.count == 35, @"background notification callbacks marshal ingestion onto the main thread");
    UNNotificationContent *notificationContent = [UNNotificationContent new];
    notificationContent.userInfo = @{@"uid": messageUID, @"mid": @"0000000000000001", @"data": [NSData dataWithBytes:"x" length:1]};
    UNNotificationRequest *notificationRequest = [UNNotificationRequest new]; notificationRequest.content = notificationContent;
    UNNotification *notification = [UNNotification new]; notification.request = notificationRequest;
    UNNotificationResponse *response = [UNNotificationResponse new]; response.notification = notification;
    response.actionIdentifier = @"open";
    [messageLogic receiveNotificationResponse:response]; finishInbox(messageLogic);
    check([messageLogic.pendingMessageID isEqual:@"0000000000000001"], @"notification route persists until SwiftUI is ready");
    [messageLogic consumePendingMessageID:@"different"];
    check(messageLogic.pendingMessageID != nil, @"unrelated route consumption does not discard pending navigation");
    [messageLogic consumePendingMessageID:@"0000000000000001"];
    response.actionIdentifier = UNNotificationDismissActionIdentifier;
    [messageLogic receiveNotificationResponse:response];
    check(messageLogic.pendingMessageID == nil, @"notification dismissal does not open a message");
    [inbox pushMessage:[NSData dataWithBytes:"x" length:1] mid:@"new" uid:messageLogic.me.uid flags:nil];
    [messageLogic refreshWatchMessages];
    [messageLogic updateUserModel:nil];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    check(messageLogic.userDataSource.testMessages.count == 35 && !messageLogic.processingInbox, @"account changes cancel scheduled inbox writes");
    puts("PASS: Watch bounded inbox ingestion, retry, discard, duplicates and account cancellation");
    TestLogic *statusLogic = [TestLogic new];
    WCSession *session = [WCSession new];
    CHUserModel *originalAccount = statusLogic.me;
    [statusLogic updateContext:session];
    check(statusLogic.configurationStatus == CHWatchConfigurationStatusWaiting && statusLogic.lastConfigurationDate == nil, @"missing context remains waiting");
    session.receivedApplicationContext = @{@"data": @"invalid"};
    [statusLogic updateContext:session];
    check(statusLogic.configurationStatus == CHWatchConfigurationStatusFailed && statusLogic.me == originalAccount, @"wrong context type reports failure without replacing account");
    session.receivedApplicationContext = @{@"data": [NSData data]};
    [statusLogic updateContext:session];
    check(statusLogic.configurationStatus == CHWatchConfigurationStatusFailed && statusLogic.me == originalAccount && statusLogic.lastConfigurationDate == nil, @"unparseable context preserves account and timestamp");
    parsedConfiguration = [CHTPWatchConfig new];
    parsedConfiguration.userKey = [NSData data];
    [statusLogic setValue:nil forKey:@"me"];
    [statusLogic updateContext:session];
    check(statusLogic.configurationStatus == CHWatchConfigurationStatusReceived && statusLogic.lastConfigurationDate != nil && statusLogic.me == nil, @"valid empty account context is received rather than waiting");
    NSDate *lastDate = statusLogic.lastConfigurationDate;
    parsedConfiguration = nil;
    [statusLogic updateContext:session];
    check(statusLogic.configurationStatus == CHWatchConfigurationStatusFailed && statusLogic.lastConfigurationDate == lastDate, @"failure preserves last successful processing time");
    TestLogic *activationLogic = [TestLogic new];
    [activationLogic session:session activationDidCompleteWithState:0 error:[NSError errorWithDomain:@"synthetic" code:1 userInfo:nil]];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    check(activationLogic.configurationStatus == CHWatchConfigurationStatusFailed, @"activation errors are visible");
    puts("PASS: Watch configuration status, invalid context preservation, activation errors");
    puts("PASS: Watch metadata, retained-key re-add, device flags, stale info/bind, identity, malformed node JSON");
} return 0; }
