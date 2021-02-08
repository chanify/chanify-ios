//
//  CHNSDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHNSDataSource.h"
#import <FMDB.h>
#import <sqlite3.h>

#define kCHNSInitSql    \
    "CREATE TABLE IF NOT EXISTS `keys`(`uid` TEXT PRIMARY KEY,`key` BLOB);"  \
    "CREATE TABLE IF NOT EXISTS `badges`(`uid` TEXT PRIMARY KEY,`badge` UNSIGNED INTEGER);"  \
    "CREATE TABLE IF NOT EXISTS `msgs`(`uid` TEXT,`mid` TEXT,`data` BLOB, PRIMARY KEY(`uid` ASC,`mid` DESC));"  \

@interface CHNSDataSource ()

@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;

@end

@implementation CHNSDataSource

+ (instancetype)dataSourceWithURL:(NSURL *)url {
    return [[self.class alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithURL:url];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            NSURL *dbURL = db.databaseURL;
            dbURL.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
            if ([db executeStatements:@kCHNSInitSql]) {
                CHLogI("Open notification service database: %s", dbURL.path.cstr);
            }
        }];
    }
    return self;
}

- (void)close {
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

- (nullable CHMessageModel *)pushMessage:(NSData *)data mid:(uint64_t)mid uid:(NSString *)uid {
    if (uid.length > 0 && mid > 0 && data.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            for (int i = 0; i < 3; i++) {
                if (![db executeUpdate:@"INSERT OR IGNORE INTO `msgs`(`uid`,`mid`,`data`) VALUES(?,?,?);", uid, @(mid), data]) {
                    switch (db.lastErrorCode) {
                        case SQLITE_BUSY:case SQLITE_LOCKED: continue;
                    }
                }
                break;
            }
        }];
        return [CHMessageModel modelWithKey:[self keyForUID:uid] data:data raw:nil];
    }
    return nil;
}

- (void)enumerateMessagesWithUID:(nullable NSString *)uid block:(void (NS_NOESCAPE ^)(uint64_t mid, NSData *data))block {
    if (uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rows = [db executeQuery:@"SELECT `mid`,`data` FROM `msgs` WHERE `uid`=? ORDER BY `mid` DESC;", uid];
            if (rows != nil) {
                while ([rows next]) {
                    uint64_t mid = [rows unsignedLongLongIntForColumnIndex:0];
                    NSData *data = [rows dataForColumnIndex:1];
                    if (mid > 0 && data.length > 0) {
                        block(mid, data);
                    }
                }
                [rows close];
            }
        }];
    }
}

- (void)removeMessages:(NSArray<NSNumber *> *)mids uid:(nullable NSString *)uid {
    if (uid.length > 0) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (NSNumber *mid in mids) {
                [db executeUpdate:@"DELETE FROM `msgs` WHERE `uid`=? AND `mid`=?;", uid, mid];
            }
        }];
    }
}


@end
