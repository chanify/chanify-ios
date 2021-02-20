//
//  CHUserDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserDataSource.h"
#import <FMDB/FMDB.h>
#import "CHMessageModel.h"
#import "CHChannelModel.h"

#define kCHDefChanCode  "0801"
#define kCHNSInitSql    \
    "CREATE TABLE IF NOT EXISTS `options`(`key` TEXT PRIMARY KEY,`value` BLOB);"   \
    "CREATE TABLE IF NOT EXISTS `messages`(`mid` UNSIGNED BIGINT PRIMARY KEY,`cid` BLOB,`from` TEXT,`raw` BLOB);"  \
    "CREATE TABLE IF NOT EXISTS `channels`(`cid` BLOB PRIMARY KEY,`name` TEXT,`icon` TEXT,`unread` UNSIGNED INTEGER,`mute` BOOLEAN,`mid` UNSIGNED BIGINT);"   \
    "INSERT OR IGNORE INTO `channels`(`cid`) VALUES(X'0801');"      \
    "INSERT OR IGNORE INTO `channels`(`cid`) VALUES(X'08011001');"  \

@interface CHUserDataSource ()

@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, nullable, strong) NSData *srvkeyCache;

@end

@implementation CHUserDataSource

@dynamic srvkey;

+ (instancetype)dataSourceWithURL:(NSURL *)url {
    return [[self.class alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _dsURL = url;
        _srvkeyCache = nil;
        _dbQueue = [FMDatabaseQueue databaseQueueWithURL:url];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if ([db executeStatements:@kCHNSInitSql]) {
                CHLogI("Open database: %s", db.databaseURL.path.cstr);
            }
        }];
    }
    return self;
}

- (void)close {
    [self.dbQueue close];
}

- (nullable NSData *)srvkey {
    if (self.srvkeyCache == nil) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            self.srvkeyCache = [db dataForQuery:@"SELECT `value` FROM `options` WHERE `key`=\"srvkey\" LIMIT 1;"];
        }];
    }
    return self.srvkeyCache;
}

- (void)setSrvkey:(nullable NSData *)srvkey {
    if (![self.srvkeyCache isEqual:srvkey]) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            BOOL res = NO;
            if (srvkey.length > 0 ) {
                res = [db executeUpdate:@"INSERT INTO `options`(`key`,`value`) VALUES(\"srvkey\",?) ON CONFLICT(`key`) DO UPDATE SET `value`=excluded.`value`;", srvkey];
            } else {
                [db executeUpdate:@"DELETE FROM `options` WHERE `key`=\"srvkey\";"];
                res = YES;
            }
            if (res) {
                self.srvkeyCache = srvkey;
            }
        }];
    }
}

- (BOOL)insertChannel:(CHChannelModel *)model {
    __block BOOL res = NO;
    if (model != nil) {
        NSData *ccid = [NSData dataFromBase64:model.cid];
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            if ([db intForQuery:@"SELECT COUNT(*) FROM `channels` WHERE `cid`=?;", ccid] > 0) {
                res = YES;
            } else {
                uint64_t mid = [db longForQuery:@"SELECT `mid` FROM `messages` WHERE `cid`=? ORDER BY `mid` DESC LIMIT 1;", ccid];
                res = [db executeUpdate:@"INSERT INTO `channels`(`cid`,`name`,`icon`,`mid`) VALUES(?,?,?,?);", ccid, model.name, model.icon, @(mid)];
            }
        }];
    }
    return res;
}

- (BOOL)updateChannel:(CHChannelModel *)model {
    __block BOOL res = NO;
    if (model != nil) {
        NSData *ccid = [NSData dataFromBase64:model.cid];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:@"UPDATE `channels` SET `name`=?,`icon`=? WHERE `cid`=? LIMIT 1;", model.name, model.icon, ccid];
        }];
    }
    return res;
}

- (BOOL)deleteChannel:(nullable NSString *)cid {
    __block BOOL res = NO;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:@"DELETE FROM `channels` WHERE `cid`=?", ccid];
        }];
    }
    return res;
}

- (NSArray<CHChannelModel *> *)loadChannels {
    __block NSMutableArray<CHChannelModel *> *cids = [NSMutableArray new];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `cid`,`name`,`icon`,`unread`,`mid` FROM `channels`;"];
        while(res.next) {
            CHChannelModel *model = [CHChannelModel modelWithCID:[res dataForColumnIndex:0].base64 name:[res stringForColumnIndex:1] icon:[res stringForColumnIndex:2]];
            if (model != nil) {
                model.mute = [res boolForColumnIndex:3];
                model.mid = [res unsignedLongLongIntForColumnIndex:4];
                [cids addObject:model];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return cids;
}

- (nullable CHChannelModel *)channelWithCID:(nullable NSString *)cid {
    __block CHChannelModel *model = nil;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid == nil) ccid = [NSData dataFromHex:@kCHDefChanCode];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `cid`,`name`,`icon`,`unread`,`mid` FROM `channels` WHERE `cid`=? LIMIT 1;", ccid];
        if (res.next) {
            model = [CHChannelModel modelWithCID:[res dataForColumnIndex:0].base64 name:[res stringForColumnIndex:1] icon:[res stringForColumnIndex:2]];
            model.mute = [res boolForColumnIndex:3];
            model.mid = [res unsignedLongLongIntForColumnIndex:4];
        }
        [res close];
        [res setParentDB:nil];
    }];
    return model;
}

- (NSArray<CHMessageModel *> *)messageWithCID:(nullable NSString *)cid from:(uint64_t)from to:(uint64_t)to count:(NSUInteger)count {
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid == nil) ccid = [NSData dataFromHex:@kCHDefChanCode];
    __block NSMutableArray<CHMessageModel *> *items = [NSMutableArray arrayWithCapacity:count];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `mid`,`raw` FROM `messages` WHERE `cid`=? AND `mid`<? AND `mid`>? ORDER BY `mid` DESC LIMIT ?;", ccid, @(from), @(to), @(count)];
        while(res.next) {
            CHMessageModel *model = [CHMessageModel modelWithData:[res dataForColumnIndex:1] mid:[res unsignedLongLongIntForColumnIndex:0]];
            if (model != nil) {
                [items addObject:model];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return items;
}

- (nullable CHMessageModel *)messageWithMID:(uint64_t)mid {
    __block CHMessageModel *model = nil;
    if (mid > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            model = [CHMessageModel modelWithData:[db dataForQuery:@"SELECT `raw` FROM `messages` WHERE `mid`=? LIMIT 1;", @(mid)] mid:mid];
        }];
    }
    return model;
}

- (BOOL)upsertMessageData:(NSData *)data mid:(uint64_t)mid cid:(NSString **)cid {
    __block BOOL res = NO;
    if (mid > 0) {
        NSData *raw = nil;
        CHMessageModel *model = [CHMessageModel modelWithKey:self.srvkey data:data raw:&raw];
        if (model != nil) {
            __block NSData *ccid = nil;
            [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                res = [db executeUpdate:@"INSERT OR IGNORE INTO `messages`(`mid`,`cid`,`from`,`raw`) VALUES(?,?,?,?);", @(mid), model.channel, model.from, raw];
                if (!res) {
                    *rollback = YES;
                } else {
                    uint64_t oldMid = 0;
                    BOOL chanFound = NO;
                    FMResultSet *result = [db executeQuery:@"SELECT `mid` FROM `channels` WHERE `cid`=? LIMIT 1;", model.channel];
                    if (result.next) {
                        oldMid = [result longLongIntForColumnIndex:0];
                        chanFound = YES;
                    }
                    [result close];
                    [result setParentDB:nil];
                    if (!chanFound) {
                        uint64_t mid = [db longForQuery:@"SELECT `mid` FROM `messages` WHERE `cid`=? ORDER BY `mid` DESC LIMIT 1;"];
                        if ([db executeUpdate:@"INSERT INTO `channels`(`cid`,`mid`) VALUES(?,?);", model.channel, @(mid)]) {
                            ccid = model.channel;
                        }
                    }
                    if (oldMid < mid) {
                        [db executeUpdate:@"UPDATE `channels` SET `mid`=? WHERE `cid`=?;", @(mid), model.channel];
                    }
                }
            }];
            if (cid != nil && ccid != nil) {
                *cid = ccid.base64;
            }
        }
    }
    return res;
}


@end
