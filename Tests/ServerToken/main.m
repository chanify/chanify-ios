#import "CHToken.h"
#import "CHNodeModel.h"
#import "CHLogic.h"
#import "CHNSDataSource.h"
#import "CHDevice.h"
#import "CHSecKey.h"
#import "CHCrpyto.h"
#import "CHTP.pbobjc.h"
#import <CommonCrypto/CommonHMAC.h>

static void check(BOOL value, NSString *message) {
    if (!value) { NSLog(@"FAIL: %@", message); exit(1); }
}
@implementation CHTestUser @end
@implementation CHLogic
+ (instancetype)shared { static CHLogic *logic; if (!logic) logic = [self new]; return logic; }
@end
@implementation CHNSDataSource
- (NSData *)keyForUID:(NSString *)uid { return self.keys[uid]; }
@end
@implementation CHDevice
+ (instancetype)shared { static CHDevice *device; if (!device) device = [self new]; return device; }
@end
@implementation CHCrpyto @end
@implementation CHSecKey
+ (instancetype)secKeyWithPublicKeyData:(NSData *)data { return nil; }
- (NSString *)formatID:(uint8_t)code { return nil; }
@end
@implementation NSString (TestVersion)
- (NSString *)localized { return self; }
- (BOOL)compareAsVersion:(NSString *)other { return [self compare:other options:NSNumericSearch] == NSOrderedDescending; }
@end
static CHNodeModel *node(NSString *nid, NSUInteger flags, NSString *features) {
    return [CHNodeModel modelWithNID:nid name:@"Synthetic node" version:@"1" endpoint:@"https://node.invalid" pubkey:nil flags:flags features:features];
}
int main(void) { @autoreleasepool {
    CHLogic.shared.me = [CHTestUser new];
    CHLogic.shared.me.uid = @"synthetic-user";
    CHLogic.shared.nsDataSource = [CHNSDataSource new];
    CHLogic.shared.nsDataSource.keys = [NSMutableDictionary new];
    NSData *key = [NSMutableData dataWithLength:64];
    CHLogic.shared.nsDataSource.keys[@"synthetic-user.node-a"] = key;
    CHNodeModel *supported = node(@"node-a", 1, @"auth.server-token");
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:86400];
    check(supported.isSupportServerToken, @"feature and stateful mode enable support");
    for (CHNodeModel *unsupported in @[node(@"sys",1,@"auth.server-token"), node(@"node-a",0,@"auth.server-token"), node(@"node-a",1,nil)]) {
        check(!unsupported.isSupportServerToken && [CHToken serverTokenForNode:unsupported date:date] == nil, @"system, forwarding and legacy nodes rejected");
    }
    check([CHToken serverTokenForNode:node(@"node-b",1,@"auth.server-token") date:date] == nil, @"missing node key does not fall back");
    check([CHToken serverTokenForNode:supported date:NSDate.distantPast] == nil, @"expired date rejected");
    NSString *raw = [CHToken serverTokenForNode:supported date:date];
    check([raw hasPrefix:@"cst1:"], @"version prefix rejects legacy parsers");
    NSArray *parts = [[raw substringFromIndex:5] componentsSeparatedByString:@"."];
    NSData *payload = [NSData dataFromBase64:parts[0]];
    CHTPToken *decoded = [CHTPToken parseFromData:payload error:nil];
    check(parts.count == 3 && [parts[1] length] == 0, @"direct node signature only");
    check(decoded.scope == CHTPTokenScope_ServerSend && decoded.channel.length == 0 && decoded.tokenId.length == 16, @"explicit scope, identifier and no default channel");
    check([decoded.nodeId isEqual:@"node-a"] && [decoded.userId isEqual:@"synthetic-user"], @"node and user bound");
    check(decoded.expires == (uint64_t)date.timeIntervalSince1970, @"expiry preserved");
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, 32, payload.bytes, payload.length, digest);
    check([[NSData dataWithBytes:digest length:sizeof(digest)] isEqual:[NSData dataFromBase64:parts[2]]], @"signature verified independently");
    check([[CHToken tokenWithString:raw].identifier isEqualToString:decoded.tokenId.hex.lowercaseString], @"identifier uses server canonical lowercase hex");
    check([CHToken tokenWithString:raw] != nil && [CHToken tokenWithString:[raw substringFromIndex:5]] == nil, @"server format cannot masquerade as channel format");
    NSString *second = [CHToken serverTokenForNode:supported date:date];
    check(![second isEqual:raw], @"separate credentials have unique identifiers");
    CHToken *legacy = [CHToken tokenWithDate:date]; legacy.node = supported; legacy.channel = [NSData dataFromHex:@"0800"];
    NSString *old = [legacy formatString:@"node-a" direct:YES];
    check(![old hasPrefix:@"cst1:"] && [CHToken tokenWithString:old] != nil, @"legacy channel format preserved");
    CHLogic.shared.nsDataSource.keys[@"synthetic-user.node-a"] = [NSMutableData dataWithLength:8];
    check([CHToken serverTokenForNode:supported date:date] == nil, @"short key rejected safely");
    NSLog(@"PASS: server token capability, isolation, payload, signature and legacy compatibility");
} return 0; }
