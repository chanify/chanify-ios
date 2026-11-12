#import "CHLogic+watchOS.h"
#import "CHUserDataSource.h"
#import "CHNodeModel.h"
#import "CHNotification.h"
#import "CHTP.pbobjc.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <WatchKit/WatchKit.h>

static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}
@implementation CHTPNode @end
@implementation CHTPBlockItem @end
@implementation CHTPWatchConfig
+ (instancetype)parseFromData:(NSData *)data error:(NSError **)error { return nil; }
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
- (void)sendNotifyWithSelector:(SEL)action withObject:(id)object {}
@end
@implementation CHNotification
+ (instancetype)shared { return nil; }
@end
@implementation CHSecKey
+ (instancetype)secKeyWithPublicKeyData:(NSData *)data { return data.length ? [self new] : nil; }
- (NSString *)formatID:(uint8_t)code { return @"node"; }
@end
@implementation CHUserModel
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
@end
@implementation CHUserDataSource
- (instancetype)init { if ((self = [super init])) { _testNodes = [NSMutableDictionary new]; _testKeys = [NSMutableDictionary new]; } return self; }
- (CHNodeModel *)nodeWithNID:(NSString *)nid { return self.testNodes[nid]; }
- (NSData *)keyForNodeID:(NSString *)nid { return self.testKeys[nid]; }
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret { self.testNodes[model.nid] = model; self.testKeys[model.nid] = secret; return YES; }
- (BOOL)updateNode:(CHNodeModel *)model { self.testNodes[model.nid] = model; return YES; }
- (BOOL)deleteNode:(NSString *)nid { [self.testNodes removeObjectForKey:nid]; return YES; }
@end
@interface CHLogicBase ()
@property (readwrite, strong) CHUserModel *me;
@property (readwrite, strong) CHUserDataSource *userDataSource;
@end
@implementation CHLogicBase
- (instancetype)initWithAppGroup:(NSString *)group { if ((self = [super init])) { _me = [CHUserModel new]; _userDataSource = [CHUserDataSource new]; } return self; }
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret { return [self.userDataSource insertNode:model secret:secret]; }
- (BOOL)updateNode:(CHNodeModel *)model { return [self.userDataSource updateNode:model]; }
- (CHNodeModel *)nodeModelWithNID:(NSString *)nid { return [self.userDataSource nodeWithNID:nid]; }
- (BOOL)deleteNode:(NSString *)nid { return [self.userDataSource deleteNode:nid]; }
@end
@interface CHLogic (TestAccess)
- (void)bindNode:(CHTPNode *)node;
@end
@interface TestLogic : CHLogic
@property (strong) NSMutableArray *loads, *binds;
@property NSUInteger unbinds, pushUpdates;
@end
@implementation TestLogic
- (instancetype)init { if ((self = [super init])) { _loads = [NSMutableArray new]; _binds = [NSMutableArray new]; } return self; }
- (void)loadNodeWitEndpoint:(NSString *)endpoint completion:(CHLogicResultBlock)completion { [self.loads addObject:[completion copy]]; }
- (void)insertNode:(CHNodeModel *)model completion:(CHLogicBlock)completion {
    __weak typeof(self) weakSelf = self;
    [self.binds addObject:[^{ BOOL ok = [weakSelf insertNode:model secret:[@"secret" dataUsingEncoding:NSUTF8StringEncoding]]; completion(ok ? CHLCodeOK : CHLCodeFailed); } copy]];
}
- (void)unbindNode:(CHNodeModel *)node { self.unbinds++; }
- (void)updatePushToken:(NSData *)token node:(CHNodeModel *)node completion:(CHLogicBlock)completion { self.pushUpdates++; }
@end
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
    puts("PASS: Watch metadata, retained-key re-add, device flags, stale info/bind, identity, malformed node JSON");
} return 0; }
