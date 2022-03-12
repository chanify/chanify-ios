//
//  CHNSDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHNSDataSource.h"
#import <FMDB.h>
#import <sqlite3.h>

#define kCHSyncVersionKey       "sync-version"
#define kCHBannerIconModeKey    "banner-icon-mode"
#define kCHNotificationSoundKey "notification-sound"
#define kCHNSInitSql    \
    "CREATE TABLE IF NOT EXISTS `keys`(`uid` TEXT PRIMARY KEY,`key` BLOB);"  \
    "CREATE TABLE IF NOT EXISTS `opts`(`uid` TEXT,`key` TEXT,`value` BLOB,PRIMARY KEY(`uid`,`key`));"  \
    "CREATE TABLE IF NOT EXISTS `badges`(`uid` TEXT PRIMARY KEY,`badge` UNSIGNED INTEGER);"  \
    "CREATE TABLE IF NOT EXISTS `msgs`(`uid` TEXT,`mid` TEXT,`data` BLOB,PRIMARY KEY(`uid` ASC,`mid` DESC));"  \
    "CREATE TABLE IF NOT EXISTS `chans`(`uid` TEXT,`cid` BLOB,`name` TEXT,`icon` TEXT,`mute` BOOLEAN,PRIMARY KEY(`uid`,`cid`));" \
    "CREATE TABLE IF NOT EXISTS `nodes`(`uid` TEXT,`nid` TEXT,`name` TEXT,`icon` TEXT,PRIMARY KEY(`uid`,`nid`));" \
    "CREATE TABLE IF NOT EXISTS `blktks`(`uid` TEXT,`key` TEXT,`raw` TEXT,`blocked` UNSIGNED INTEGER DEFAULT 0,`createtime` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(`uid`,`key`));" \

@interface CHNSDataSource ()

@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;

@end

@implementation CHNSDataSource

+ (instancetype)dataSourceWithURL:(NSURL *)url {
    return [[self.class alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithURL:url flags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|kCHDBFileProtectionFlags];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if ([db executeStatements:@kCHNSInitSql]) {
                NSURL *dbURL = db.databaseURL;
                dbURL.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
                CHLogI("Open notification service database: %s", dbURL.path.cstr);
            }
        }];
    }
    return self;
}

- (void)close {
    [self.dbQueue close];
}

- (void)flush {
    [self.dbQueue close];
}

- (nullable NSData *)keyForUID:(nullable NSString *)uid {
    __block NSData *key = nil;
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            key = [db dataForQuery:@"SELECT `key` FROM `keys` WHERE `uid`=? LIMIT 1;", uid];
        }];
    }
    return key;
}

- (void)updateKey:(nullable NSData *)key uid:(nullable NSString *)uid {
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if (key.length <= 0) {
                [db executeUpdate:@"DELETE FROM `keys` WHERE `uid`=?;", uid];
            } else {
                [db executeUpdate:@"INSERT INTO `keys`(`uid`,`key`) VALUES(?,?) ON CONFLICT(`uid`) DO UPDATE SET `key`=excluded.`key`;", uid, key];
            }
        }];
    }
}

- (NSInteger)syncVersionForUID:(nullable NSString *)uid {
    __block NSInteger version = 0;
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            version = [db intForQuery:@"SELECT `value` FROM `opts` WHERE `uid`=? AND `key`=? LIMIT 1;", uid, @kCHSyncVersionKey];
        }];
    }
    return version;
}

- (void)updateSyncVersion:(NSInteger)version uid:(nullable NSString *)uid {
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT INTO `opts`(`uid`,`key`,`value`) VALUES(?,?,?) ON CONFLICT(`uid`,`key`) DO UPDATE SET `value`=excluded.`value`;", uid, @kCHSyncVersionKey, @(version)];
        }];
    }
}

- (NSString *)notificationSoundForUID:(nullable NSString *)uid {
    __block NSString *sound = @"";
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            sound = [db stringForQuery:@"SELECT `value` FROM `opts` WHERE `uid`=? AND `key`=? LIMIT 1;", uid, @kCHNotificationSoundKey];
        }];
    }
    return sound ?: @"";
}

- (void)updateNotificationSound:(NSString *)sound uid:(nullable NSString *)uid {
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT INTO `opts`(`uid`,`key`,`value`) VALUES(?,?,?) ON CONFLICT(`uid`,`key`) DO UPDATE SET `value`=excluded.`value`;", uid, @kCHNotificationSoundKey, sound ?: @""];
        }];
    }
}

- (CHBannerIconMode)bannerIconModeForUID:(nullable NSString *)uid API_AVAILABLE(ios(15.0), macos(12.0), watchos(8.0)) {
    __block CHBannerIconMode iconMode = CHBannerIconModeNone;
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            iconMode = [db intForQuery:@"SELECT `value` FROM `opts` WHERE `uid`=? AND `key`=? LIMIT 1;", uid, @kCHBannerIconModeKey];
        }];
    }
    return iconMode;
}

- (void)updateBannerIconMode:(CHBannerIconMode)iconMode uid:(nullable NSString *)uid API_AVAILABLE(ios(15.0), macos(12.0), watchos(8.0)) {
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT INTO `opts`(`uid`,`key`,`value`) VALUES(?,?,?) ON CONFLICT(`uid`,`key`) DO UPDATE SET `value`=excluded.`value`;", uid, @kCHBannerIconModeKey, @(iconMode)];
        }];
    }
}

- (NSUInteger)badgeForUID:(nullable NSString *)uid {
    __block NSUInteger badge = 0;
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            badge = [db longForQuery:@"SELECT `badge` FROM `badges` WHERE `uid`=? LIMIT 1;", uid];
        }];
    }
    return badge;
}

- (NSUInteger)nextBadgeForUID:(nullable NSString *)uid {
    __block NSUInteger badge = 0;
    if (uid.length > 0) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"INSERT INTO `badges`(`uid`,`badge`) VALUES(?,1) ON CONFLICT(`uid`) DO UPDATE SET `badge`=`badge`+1;", uid];
            badge = [db longForQuery:@"SELECT `badge` FROM `badges` WHERE `uid`=? LIMIT 1;", uid];
        }];
    }
    return badge;
}

- (void)updateBadge:(NSUInteger)badge uid:(nullable NSString *)uid {
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT INTO `badges`(`uid`,`badge`) VALUES(?,?) ON CONFLICT(`uid`) DO UPDATE SET `badge`=excluded.`badge`;", uid, @(badge)];
        }];
    }
}

- (nullable CHMessageModel *)pushMessage:(NSData *)data mid:(NSString *)mid uid:(NSString *)uid flags:(CHMessageProcessFlags * _Nullable)flags {
    CHMessageModel *msg = nil;
    CHMessageProcessFlags uFlags = 0;
    if (uid.length > 0 && mid.length > 0 && data.length > 0) {
        msg = [CHMessageModel modelWithStorage:self uid:uid mid:mid data:data raw:nil flags:&uFlags];
        if ((uFlags&CHMessageProcessFlagBlocked) != CHMessageProcessFlagBlocked) {
            [self.dbQueue inDatabase:^(FMDatabase *db) {
                for (int i = 0; i < 3; i++) {
                    if (![db executeUpdate:@"INSERT OR IGNORE INTO `msgs`(`uid`,`mid`,`data`) VALUES(?,?,?);", uid, mid, data]) {
                        switch (db.lastErrorCode) {
                            case SQLITE_BUSY:case SQLITE_LOCKED: continue;
                        }
                    }
                    break;
                }
            }];
        }
    }
    if (flags != nil) {
        *flags = uFlags;
    }
    return msg;
}

- (void)enumerateMessagesWithUID:(nullable NSString *)uid block:(void (NS_NOESCAPE ^)(FMDatabase *db, NSString *mid, NSData *data))block {
    if (uid.length > 0 && block != nil) {
        [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            FMResultSet *rows = [db executeQuery:@"SELECT `mid`,`data` FROM `msgs` WHERE `uid`=? ORDER BY `mid` ASC;", uid];
            if (rows != nil) {
                while ([rows next]) {
                    NSString *mid = [rows stringForColumnIndex:0];
                    NSData *data = [rows dataForColumnIndex:1];
                    if (mid.length > 0 && data.length > 0) {
                        block(db, mid, data);
                    }
                }
                [rows close];
            }
        }];
    }
}

- (void)removeMessages:(NSArray<NSString *> *)mids uid:(nullable NSString *)uid {
    if (uid.length > 0) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (NSString *mid in mids) {
                [db executeUpdate:@"DELETE FROM `msgs` WHERE `uid`=? AND `mid`=?;", uid, mid];
            }
        }];
    }
}

- (BOOL)checkBlockedTokenWithKey:(nullable NSString *)key uid:(nullable NSString *)uid {
    __block BOOL res = NO;
    if (key.length > 0 && uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db intForQuery:@"SELECT COUNT(*) FROM `blktks` WHERE `uid`=? AND `key`=? LIMIT 1;", uid, key] > 0) {
                res = YES;
            }
        }];
    }
    return res;
}

- (BOOL)upsertBlockedToken:(nullable NSString *)token uid:(nullable NSString *)uid {
    __block BOOL res = NO;
    if (token.length > 0 && uid.length > 0) {
        NSString *key = [token dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db executeUpdate:@"INSERT OR IGNORE INTO `blktks`(`uid`,`key`,`raw`) VALUES(?,?,?);", uid, key, token]) {
                res = (db.changes > 0);
            }
        }];
    }
    return res;
}

- (BOOL)removeBlockedTokens:(NSArray<NSString *> *)tokens uid:(nullable NSString *)uid {
    __block BOOL res = NO;
    if (tokens.count > 0 && uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            for (NSString *token in tokens) {
                if ([db executeUpdate:@"DELETE FROM `blktks` WHERE `uid`=? AND `raw`=? LIMIT 1;", uid, token]) {
                    res = (res || db.changes > 0);
                }
            }
        }];
    }
    return res;
}

- (NSArray<NSString *> *)blockedTokensWithUID:(nullable NSString *)uid {
    NSMutableArray<NSString *> *tokens = [NSMutableArray new];
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            FMResultSet *res = [db executeQuery:@"SELECT `raw` FROM `blktks` WHERE `uid`=? ORDER BY `createtime` DESC;", uid];
            while (res.next) {
                [tokens addObject:[res stringForColumnIndex:0]];
            }
        }];
    }
    return tokens;
}

// Nodes
- (nullable NSString *)nodeIconWithNID:(nullable NSString *)nid uid:(nullable NSString *)uid API_UNAVAILABLE(tvos) {
    __block NSString *icon = nil;
    if (nid.length > 0 && uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            icon = [db stringForQuery:@"SELECT `icon` FROM `nodes` WHERE `uid`=? AND `nid`=? LIMIT 1;", uid, nid];
        }];
    }
    return icon;
}

- (BOOL)upsertNode:(CHNodeModel *)model uid:(nullable NSString *)uid {
    __block BOOL res = YES;
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            res = [db executeUpdate:@"INSERT INTO `nodes`(`uid`,`nid`,`name`,`icon`) VALUES(?,?,?,?) ON CONFLICT(`uid`,`nid`) DO UPDATE SET `name`=excluded.`name`,`icon`=excluded.`icon`;", uid, model.nid, model.name, model.icon];
        }];
    }
    return res;
}

- (BOOL)deleteNode:(nullable NSString *)nid uid:(nullable NSString *)uid {
    __block BOOL res = YES;
    if (nid.length > 0 && uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            res = [db executeUpdate:@"DELETE FROM `nodes` WHERE `uid`=? AND `nid`=? LIMIT 1;", uid, nid];
        }];
    }
    return res;
}

// Channels
- (nullable NSString *)channelIconWithCID:(nullable NSString *)cid uid:(nullable NSString *)uid {
    __block NSString *icon = nil;
    if (cid.length > 0 && uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            icon = [db stringForQuery:@"SELECT `icon` FROM `chans` WHERE `uid`=? AND `cid`=? LIMIT 1;", uid, cid];
        }];
    }
    return icon;
}

- (BOOL)upsertChannel:(CHChannelModel *)model uid:(nullable NSString *)uid {
    __block BOOL res = YES;
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            res = [db executeUpdate:@"INSERT INTO `chans`(`uid`,`cid`,`name`,`icon`) VALUES(?,?,?,?) ON CONFLICT(`uid`,`cid`) DO UPDATE SET `name`=excluded.`name`,`icon`=excluded.`icon`;", uid, model.cid, model.name, model.icon];
        }];
    }
    return res;
}

- (BOOL)deleteChannel:(nullable NSString *)cid uid:(nullable NSString *)uid {
    __block BOOL res = YES;
    if (cid.length > 0 && uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            res = [db executeUpdate:@"DELETE FROM `chans` WHERE `uid`=? AND `cid`=? LIMIT 1;", uid, cid];
        }];
    }
    return res;
}

@end

@interface CHTempNSDatasource ()

@property (nonatomic, readonly, strong) FMDatabase *db;

@end

@implementation CHTempNSDatasource

+ (instancetype)datasourceFromDB:(FMDatabase *)db {
    return [[self.class alloc] initWithDB:db];
}

- (instancetype)initWithDB:(FMDatabase *)db {
    if (self = [super init]) {
        _db = db;
    }
    return self;
}

- (nullable NSData *)keyForUID:(nullable NSString *)uid {
    NSData *key = nil;
    if (uid.length > 0) {
        key = [self.db dataForQuery:@"SELECT `key` FROM `keys` WHERE `uid`=? LIMIT 1;", uid];
    }
    return key;
}

- (BOOL)checkBlockedTokenWithKey:(nullable NSString *)key uid:(nullable NSString *)uid {
    BOOL res = NO;
    if (key.length > 0 && uid.length > 0) {
        res = ([self.db intForQuery:@"SELECT COUNT(*) FROM `blktks` WHERE `uid`=? AND `key`=? LIMIT 1;", uid, key] > 0);
    }
    return res;
}


@end

