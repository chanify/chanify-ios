//
//  CHNodeModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeModel.h"
#import "CHSecKey.h"

@implementation CHNodeModel

+ (instancetype)modelWithNID:(nullable NSString *)nid name:(nullable NSString *)name version:(nullable NSString *)version endpoint:(nullable NSString *)endpoint pubkey:(nullable NSData *)pubkey flags:(CHNodeModelFlags)flags features:(nullable NSString *)features {
    if (nid != nil) {
        return [[self.class alloc] initWithNID:nid name:name version:version endpoint:endpoint pubkey:pubkey flags:flags features:features];
    }
    return nil;
}

+ (instancetype)modelWithNSDictionary:(NSDictionary *)info {
    if (info.count > 0) {
        NSString *nid = [info valueForKey:@"nodeid"];
        if (nid.length > 0) {
            NSData *pubKey = [NSData dataFromBase64:[info valueForKey:@"pubkey"]];
            if (pubKey.length > 0 && [CHNodeModel verifyNID:nid pubkey:pubKey]) {
                return [CHNodeModel modelWithNID:nid name:[info valueForKey:@"name"] version:[info valueForKey:@"version"] endpoint:[info valueForKey:@"endpoint"] pubkey:pubKey flags:0 features:[[info valueForKey:@"features"] componentsJoinedByString:@","]];
            }
        }
    }
    return nil;
}

+ (BOOL)verifyNID:(nullable NSString *)nid pubkey:(NSData *)pubkey {
    BOOL res = NO;
    if (nid.length > 0 && pubkey.length > 0) {
        CHSecKey *seckey = [CHSecKey secKeyWithPublicKeyData:pubkey];
        res = (seckey != nil && [nid isEqualToString:[seckey formatID:0x01]]);
    }
    return res;
}

- (instancetype)initWithNID:(NSString *)nid name:(nullable NSString *)name version:(nullable NSString *)version endpoint:(nullable NSString *)endpoint pubkey:(nullable NSData *)pubkey flags:(CHNodeModelFlags)flags features:(nullable NSString *)features {
    if (self = [super init]) {
        _nid = nid;
        _name = name;
        _version = (version ?: @"");
        _endpoint = (endpoint ?: @"");
        _pubkey = pubkey;
        _flags = flags;
        _features = [features componentsSeparatedByString:@","];
        if ([nid isEqualToString:@"sys"]) {
            if (name.length <= 0) _name = @"Chanify".localized;
            if (endpoint.length <= 0) _endpoint = [@"https://" stringByAppendingString:@kCHAPIHostname];
        }
        if (self.endpoint.length > 0 && self.name.length <= 0) {
            NSURL *url = [NSURL URLWithString:self.endpoint];
            _name = url.host;
        }
        if (self.name.length <= 0) {
            _name = @"";
        }
    }
    return self;
}

- (BOOL)isEqual:(CHNodeModel *)rhs {
    return ([self.nid isEqualToString:rhs.nid]
            && (self.name == rhs.name || [self.name isEqualToString:rhs.name])
            && (self.endpoint == rhs.endpoint || [self.endpoint isEqualToString:rhs.endpoint])
            && self.flags == rhs.flags
            && (self.icon == rhs.icon || [self.icon isEqualToString:rhs.icon])
            && (self.features == rhs.features || [[self.features componentsJoinedByString:@","] isEqualToString:[rhs.features componentsJoinedByString:@","]]));
}

- (NSUInteger)hash {
    return self.nid.hash;
}

- (void)setVersion:(nullable NSString *)version {
    if ([version integerValue] > 0) {
        _version = version;
    }
}

- (void)setEndpoint:(nullable NSString *)endpoint {
    if (endpoint.length > 0) {
        _endpoint = endpoint;
    }
}

- (void)setFeatures:(nullable NSString *)features {
    NSArray *fs = [features componentsSeparatedByString:@","];
    if (fs.count > 0) {
        _features = fs;
    }
}

- (BOOL)isHigherVersion:(NSString *)version {
    BOOL res = NO;
    if (self.version.length > 0) {
        return [self.version compareAsVersion:version];
    }
    return res;
}

- (nullable CHSecKey *)requestChiper {
    CHSecKey *seckey = nil;
    if (!self.isSystem && self.pubkey.length > 0 && ![self.endpoint.lowercaseString hasPrefix:@"https"] && [self isHigherVersion:@kCHNodeCanCipherVersion]) {
        seckey = [CHSecKey secKeyWithPublicKeyData:self.pubkey];
    }
    return seckey;
}

- (NSURL *)apiURL {
    return [[NSURL URLWithString:self.endpoint] URLByAppendingPathComponent:@"/rest/v1/"];
}

- (BOOL)isSupportWatch {
    return [self.features containsObject:@"platform.watchos"];
}

- (BOOL)isStoreDevice {
    return (self != nil && self.flags&CHNodeModelFlagsStoreDevice);
}

- (BOOL)isSystem {
    return (self.nid.length <= 0 || [self.nid isEqualToString:@"sys"]);
}


@end
