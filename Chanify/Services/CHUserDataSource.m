//
//  CHUserDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserDataSource.h"
#import <FMDB/FMDB.h>
#import <sqlite3.h>
#import "CHNSDataSource.h"
#import "CHScriptModel.h"
#import "CHMessageModel.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHMessageSearch.h"

#define kCHUserDBBaseVersion    3
#define kCHNSInitSql        \
    "CREATE TABLE IF NOT EXISTS `options`(`key` TEXT PRIMARY KEY,`value` BLOB);"   \
    "CREATE TABLE IF NOT EXISTS `messages`(`mid` TEXT PRIMARY KEY,`cid` BLOB,`from` TEXT,`raw` BLOB);"  \
    "CREATE TABLE IF NOT EXISTS `channels`(`cid` BLOB PRIMARY KEY,`hidden` BOOLEAN DEFAULT 0,`deleted` BOOLEAN DEFAULT 0,`name` TEXT,`icon` TEXT,`unread` UNSIGNED INTEGER DEFAULT 0,`mute` BOOLEAN,`mid` TEXT);"   \
    "CREATE TABLE IF NOT EXISTS `nodes`(`nid` TEXT PRIMARY KEY,`deleted` BOOLEAN DEFAULT 0,`name` TEXT,`version` TEXT,`endpoint` TEXT,`pubkey` BLOB,`icon` TEXT,`flags` INTEGER DEFAULT 0,`features` TEXT,`secret` BLOB);" \
    "CREATE TABLE IF NOT EXISTS `scripts`(`name` TEXT PRIMARY KEY,`type` TEXT,`script` BLOB,`lastupdate` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,`createtime` TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"  \
    "INSERT OR IGNORE INTO `channels`(`cid`) VALUES(X'0801');"      \
    "INSERT OR IGNORE INTO `channels`(`cid`) VALUES(X'08011001');"  \
    "INSERT OR IGNORE INTO `channels`(`cid`) VALUES(X'08011002');"  \
    "INSERT OR IGNORE INTO `nodes`(`nid`,`features`) VALUES(\"sys\",\"store.device,platform.watchos,msg.text,msg.link,msg.action\") ON CONFLICT(`nid`) DO UPDATE SET `features`=excluded.`features` WHERE `features`!=excluded.`features`;"  \

@interface CHUserDataSource ()

@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) dispatch_queue_t messageReadQueue;
@property (nonatomic, nullable, strong) NSData *srvkeyCache;
@property (nonatomic, readwrite, nullable, strong) CHMessageSearch *messageSearch;
@property (nonatomic) BOOL searchTrackingReady;
@property (atomic) BOOL closed;

@end

static int CHMessageReadCancelled(void *context) {
    return [(__bridge CHUserDataSource *)context closed];
}

@implementation CHUserDataSource

@dynamic srvkey;

+ (instancetype)dataSourceWithURL:(NSURL *)url {
    return [[self.class alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _dsURL = url;
        _messageReadQueue = dispatch_queue_create("net.chanify.messages.read", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0));
        _srvkeyCache = nil;
        _dbQueue = [FMDatabaseQueue databaseQueueWithURL:url flags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|kCHDBFileProtectionFlags];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if (![db beginTransaction]) return;
            BOOL res = YES;
            if (db.applicationID > 0) {
                db.userVersion = db.applicationID;
                db.applicationID = 0;
            }
            if (db.userVersion < kCHUserDBBaseVersion) {
                if ([db tableExists:@"nodes"]) {
                    if (![db columnExists:@"version" inTableWithName:@"nodes"]
                        && ![db executeStatements:@"ALTER TABLE `nodes` ADD COLUMN `version` TEXT;"]) {
                        res = NO;
                    }
                    if (![db columnExists:@"flags" inTableWithName:@"nodes"]
                        && ![db executeStatements:@"ALTER TABLE `nodes` ADD COLUMN `flags` INTEGER DEFAULT 0;"]) {
                        res = NO;
                    }
                    if (![db columnExists:@"pubkey" inTableWithName:@"nodes"]
                        && ![db executeStatements:@"ALTER TABLE `nodes` ADD COLUMN `pubkey` BLOB;"]) {
                        res = NO;
                    }
                    if (![db columnExists:@"hidden" inTableWithName:@"channels"]
                        && ![db executeStatements:@"ALTER TABLE `channels` ADD COLUMN `hidden` BOOLEAN DEFAULT 0;"]) {
                        res = NO;
                    }
                }
            }
            res = res && [db executeStatements:@kCHNSInitSql];
            if (res && db.userVersion < kCHUserDBBaseVersion) db.userVersion = kCHUserDBBaseVersion;
            if (res) res = [db commit];
            if (!res) [db rollback];
            if (res) {
                NSURL *dbURL = db.databaseURL;
                dbURL.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
                CHLogI("Open database: %s", dbURL.path.cstr);
            }
        }];
#if TARGET_OS_IOS
        // Add only lightweight tracking here. FTS initialization never runs in message writes.
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if (db.userVersion == 3 || db.userVersion == 4) self.searchTrackingReady = [CHMessageSearch prepareTrackingInDatabase:db];
        }];
        if (self.searchTrackingReady && url.isFileURL) {
            __block BOOL wal = NO;
            [self.dbQueue inDatabase:^(FMDatabase *db) {
                // WAL allows the separate search reader to coexist with message writes.
                wal = [[db stringForQuery:@"PRAGMA journal_mode=WAL;"] isEqualToString:@"wal"];
            }];
            if (wal) {
                _messageSearch = [[CHMessageSearch alloc] initWithURL:url extractor:^NSDictionary *(NSData *data, NSString *mid) {
                    CHMessageModel *model = [CHMessageModel modelWithData:data mid:mid];
                    return model ? @{ @"title": model.title ?: @"", @"text": model.text ?: @"" } : nil;
                }];
            }
        }
#endif
    }
    return self;
}

- (void)dealloc {
    [self.messageSearch close];
}

- (void)close {
    self.closed = YES;
    [self.messageSearch close];
    self.messageSearch = nil;
    [self.dbQueue close];
}

- (void)flush {
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
            if (srvkey.length > 0) {
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

- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret {
    __block BOOL res = NO;
    if (model != nil) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            res = [db executeUpdate:@"INSERT INTO `nodes`(`nid`,`name`,`version`,`endpoint`,`pubkey`,`icon`,`flags`,`features`,`secret`) VALUES(?,?,?,?,?,?,?,?,?) ON CONFLICT(`nid`) DO UPDATE SET `name`=excluded.`name`,`version`=excluded.`version`,`endpoint`=excluded.`endpoint`,`pubkey`=excluded.`pubkey`,`icon`=excluded.`icon`,`flags`=excluded.`flags`,`features`=excluded.`features`,`secret`=excluded.`secret`,`deleted`=0;", model.nid, model.name, model.version, model.endpoint, model.pubkey, model.icon, @(model.flags), [model.features componentsJoinedByString:@","], secret];
        }];
    }
    return res;
}

- (BOOL)updateNode:(CHNodeModel *)model {
    __block BOOL res = NO;
    if (model != nil) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:@"UPDATE `nodes` SET `name`=?,`version`=?,`endpoint`=?,`pubkey`=?,`icon`=?,`flags`=?,`features`=? WHERE `nid`=? LIMIT 1;", model.name, model.version, model.endpoint, model.pubkey, model.icon, @(model.flags), [model.features componentsJoinedByString:@","], model.nid];
        }];
    }
    return res;
}

- (BOOL)deleteNode:(nullable NSString *)nid {
    __block BOOL res = NO;
    if (nid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:@"UPDATE `nodes` SET `deleted`=1 WHERE `nid`=? LIMIT 1;", nid];
        }];
    }
    return res;
}

- (nullable NSData *)keyForNodeID:(nullable NSString *)nid {
    __block NSData *res = nil;
    if (nid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db dataForQuery:@"SELECT `secret` FROM `nodes` WHERE `nid`=? LIMIT 1;", nid];
        }];
    }
    return res;
}

- (NSArray<CHNodeModel *> *)loadNodes {
    __block NSMutableArray<CHNodeModel *> *nodes = [NSMutableArray new];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `nid`,`name`,`version`,`endpoint`,`pubkey`,`flags`,`features`,`icon` FROM `nodes` WHERE `deleted`=0;"];
        while(res.next) {
            CHNodeModel *model = [CHNodeModel modelWithNID:[res stringForColumnIndex:0] name:[res stringForColumnIndex:1] version:[res stringForColumnIndex:2] endpoint:[res stringForColumnIndex:3] pubkey:[res dataForColumnIndex:4] flags:(CHNodeModelFlags)[res unsignedLongLongIntForColumnIndex:5] features:[res stringForColumnIndex:6]];
            if (model != nil) {
                model.icon = [res stringForColumnIndex:7];
                [nodes addObject:model];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return nodes;
}

- (nullable CHNodeModel *)nodeWithNID:(nullable NSString *)nid {
    __block CHNodeModel *model = nil;
    if (nid == nil) nid = @"";
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `nid`,`name`,`version`,`endpoint`,`pubkey`,`flags`,`features`,`icon` FROM `nodes` WHERE `nid`=? AND `deleted`=0; LIMIT 1;", nid];
        if (res.next) {
            model = [CHNodeModel modelWithNID:[res stringForColumnIndex:0] name:[res stringForColumnIndex:1] version:[res stringForColumnIndex:2] endpoint:[res stringForColumnIndex:3] pubkey:[res dataForColumnIndex:4] flags:(CHNodeModelFlags)[res unsignedLongLongIntForColumnIndex:5] features:[res stringForColumnIndex:6]];
            if (model != nil) {
                model.icon = [res stringForColumnIndex:7];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return model;
}

- (BOOL)insertChannel:(CHChannelModel *)model {
    __block BOOL res = NO;
    if (model != nil) {
        NSData *ccid = [NSData dataFromBase64:model.cid];
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSString *mid = [db stringForQuery:@"SELECT `mid` FROM `messages` WHERE `cid`=? ORDER BY `mid` DESC LIMIT 1;", ccid];
            res = [db executeUpdate:@"INSERT INTO `channels`(`cid`,`name`,`icon`,`mid`) VALUES(?,?,?,?) ON CONFLICT(`cid`) DO UPDATE SET `name`=excluded.`name`,`icon`=excluded.`icon`,`mid`=excluded.`mid`,`deleted`=0;", ccid, model.name, model.icon, mid];
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
            res = [db executeUpdate:@"UPDATE `channels` SET `deleted`=1,`unread`=0 WHERE `cid`=? LIMIT 1;", ccid];
        }];
    }
    return res;
}

- (BOOL)channelIsHidden:(nullable NSString *)cid {
    __block BOOL res = NO;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db boolForQuery:@"SELECT `hidden` FROM `channels` WHERE `cid`=? LIMIT 1;", ccid];
        }];
    }
    return res;
}

- (BOOL)updateChannelWithCID:(nullable NSString *)cid hidden:(BOOL)hidden {
    __block BOOL res = NO;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:@"UPDATE `channels` SET `hidden`=? WHERE `cid`=? LIMIT 1;", @(hidden), ccid];
        }];
    }
    return res;
}

- (NSArray<CHChannelModel *> *)loadAllChannels {
    return [self loadChannelsIncludeHidden:YES];
}

- (NSArray<CHChannelModel *> *)loadChannelsIncludeHidden:(BOOL)hidden {
    __block NSMutableArray<CHChannelModel *> *cids = [NSMutableArray new];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *hidSql = (hidden ? @"" : @" AND `hidden`==0");
        FMResultSet *res = [db executeQuery:[NSString stringWithFormat:@"SELECT `cid`,`name`,`icon`,`mid` FROM `channels` WHERE `deleted`=0%@;", hidSql]];
        while(res.next) {
            CHChannelModel *model = [CHChannelModel modelWithCID:[res dataForColumnIndex:0].base64Code name:[res stringForColumnIndex:1] icon:[res stringForColumnIndex:2]];
            if (model != nil) {
                model.mid = [res stringForColumnIndex:3];
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
        FMResultSet *res = [db executeQuery:@"SELECT `cid`,`name`,`icon`,`mid` FROM `channels` WHERE `cid`=? LIMIT 1;", ccid];
        if (res.next) {
            model = [CHChannelModel modelWithCID:[res dataForColumnIndex:0].base64Code name:[res stringForColumnIndex:1] icon:[res stringForColumnIndex:2]];
            if (model != nil) {
                model.mid = [res stringForColumnIndex:3];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return model;
}

- (NSInteger)unreadSumAllChannel {
    __block NSInteger unread = 0;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        unread = [db intForQuery:@"SELECT SUM(`unread`) FROM `channels` WHERE IFNULL(`deleted`,0)=0;"];
    }];
    return unread;
}

- (NSInteger)unreadWithChannel:(nullable NSString *)cid {
    __block NSInteger unread = 0;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid == nil) ccid = [NSData dataFromHex:@kCHDefChanCode];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        unread = [db intForQuery:@"SELECT `unread` FROM `channels` WHERE `cid`=? LIMIT 1;", ccid];
    }];
    return unread;
}

- (BOOL)clearUnreadWithChannel:(nullable NSString *)cid {
    __block BOOL res = NO;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid == nil) ccid = [NSData dataFromHex:@kCHDefChanCode];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:@"UPDATE OR IGNORE `channels` SET `unread`=0 WHERE `cid`=? AND `unread`>0 LIMIT 1;", ccid];
    }];
    return res;
}

- (BOOL)deleteMessage:(NSString *)mid {
    if (!mid.length) return YES;
    __block BOOL success = NO;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSData *cid = [db dataForQuery:@"SELECT cid FROM channels WHERE mid=? LIMIT 1;", mid];
        success = [db executeUpdate:@"DELETE FROM messages WHERE mid=?;", mid];
        if (success && cid.length) {
            NSString *latest = [db stringForQuery:@"SELECT mid FROM messages WHERE cid=? ORDER BY mid DESC LIMIT 1;", cid];
            success = [db executeUpdate:@"UPDATE channels SET mid=? WHERE cid=?;", latest, cid];
        }
        *rollback = !success;
    }];
    if (success) [self.messageSearch requestIndexing];
    return success;
}

- (BOOL)deleteMessages:(NSArray<NSString *> *)mids {
    if (!mids.count) return YES;
    __block BOOL success = NO;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableSet<NSData *> *channels = [NSMutableSet new];
        for (NSString *mid in mids) {
            NSData *cid = [db dataForQuery:@"SELECT cid FROM channels WHERE mid=? LIMIT 1;", mid];
            if (cid.length) [channels addObject:cid];
            if (![db executeUpdate:@"DELETE FROM messages WHERE mid=?;", mid]) { *rollback = YES; return; }
        }
        for (NSData *cid in channels) {
            NSString *latest = [db stringForQuery:@"SELECT mid FROM messages WHERE cid=? ORDER BY mid DESC LIMIT 1;", cid];
            if (![db executeUpdate:@"UPDATE channels SET mid=? WHERE cid=?;", latest, cid]) { *rollback = YES; return; }
        }
        success = YES;
    }];
    if (success) [self.messageSearch requestIndexing];
    return success;
}

- (BOOL)deleteMessagesWithCID:(nullable NSString *)cid {
    __block BOOL res = NO;
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid == nil) ccid = [NSData dataFromHex:@kCHDefChanCode];
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if (![db executeUpdate:@"DELETE FROM `messages` WHERE `cid`=?;", ccid]) {
            *rollback = YES;
            return;
        }
        res = [db executeUpdate:@"UPDATE `channels` SET `mid`=NULL,`unread`=0 WHERE `cid`=?;", ccid];
        *rollback = !res;
    }];
    if (res) [self.messageSearch requestIndexing];
    return res;
}

- (NSArray<CHMessageModel *> *)messageWithCID:(nullable NSString *)cid from:(NSString *)from to:(NSString *)to count:(NSUInteger)count {
    NSData *ccid = [NSData dataFromBase64:cid];
    if (ccid == nil) ccid = [NSData dataFromHex:@kCHDefChanCode];
    __block NSMutableArray<CHMessageModel *> *items = [NSMutableArray arrayWithCapacity:count];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `mid`,`raw` FROM `messages` WHERE `cid`=? AND `mid`<? AND `mid`>? ORDER BY `mid` DESC LIMIT ?;", ccid, from, to, @(count)];
        while(res.next) {
            CHMessageModel *model = [CHMessageModel modelWithData:[res dataForColumnIndex:1] mid:[res stringForColumnIndex:0]];
            if (model != nil) {
                [items addObject:model];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return items;
}

- (void)readMessagesWithSQL:(NSString *)sql arguments:(NSArray *)arguments reverse:(BOOL)reverse completion:(CHMessageLoadCompletion)completion {
    dispatch_async(self.messageReadQueue, ^{
        if (self.closed) return;
        NSMutableArray *items = [NSMutableArray new];
        __block NSError *error = nil;
        void (^read)(FMDatabase *) = ^(FMDatabase *db) {
            if (self.closed) return;
            sqlite3_progress_handler(db.sqliteHandle, 2000, CHMessageReadCancelled, (__bridge void *)self);
            FMResultSet *result = [db executeQuery:sql withArgumentsInArray:arguments];
            if (!result) error = db.lastError;
            while ([result next] && !self.closed) {
                CHMessageModel *model = [CHMessageModel modelWithData:[result dataForColumnIndex:1] mid:[result stringForColumnIndex:0]];
                if (model) [items addObject:model];
            }
            if (db.lastErrorCode != SQLITE_OK && db.lastErrorCode != SQLITE_ROW && db.lastErrorCode != SQLITE_DONE) error = db.lastError;
            [result close];
            sqlite3_progress_handler(db.sqliteHandle, 0, NULL, NULL);
        };
        if (self.dsURL.isFileURL) {
            // No work is submitted to the message writer's queue for on-disk paging.
            FMDatabase *db = [FMDatabase databaseWithURL:self.dsURL];
            if ([db openWithFlags:SQLITE_OPEN_READONLY]) {
                db.maxBusyRetryTimeInterval = 0.1;
                read(db);
            } else {
                error = db.lastError ?: [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
            }
            [db close];
        } else {
            // Isolated in-memory fixtures must use their original connection, off the UI thread.
            [self.dbQueue inDatabase:read];
        }
        NSArray *messages = reverse ? items.reverseObjectEnumerator.allObjects : items.copy;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.closed) completion(error ? @[] : messages, error);
        });
    });
}

#if TARGET_OS_WATCH
- (nullable NSString *)repairWatchMessagesAfterMID:(NSString *)mid storage:(id<CHKeyStorage, CHBlockedStorage>)storage uid:(NSString *)uid limit:(NSUInteger)limit pending:(BOOL *)pending error:(NSError **)error {
    if (error != nil) *error = nil;
    __block NSError *failure = nil;
    __block NSString *cursor = nil;
    __block BOOL needsKey = *pending;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        // A completed repair is a read-only no-op, including while a page reader
        // holds a snapshot. Take the write lock only when repair is still needed.
        if ([db intForQuery:@"SELECT value FROM options WHERE key='watch-encrypted-cache-repaired-v1';"] == 1) return;
        if (db.lastErrorCode != SQLITE_OK && db.lastErrorCode != SQLITE_ROW && db.lastErrorCode != SQLITE_DONE) {
            failure = db.lastError;
            return;
        }
        if (![db beginTransaction]) { failure = db.lastError; return; }
        NSMutableArray *batch = [NSMutableArray new];
        FMResultSet *rows = [db executeQuery:@"SELECT mid,raw FROM messages WHERE mid>? ORDER BY mid ASC LIMIT ?;", mid, @(MIN(MAX(limit, 1), 32))];
        if (!rows) failure = db.lastError;
        while ([rows next]) {
            NSString *messageID = [rows stringForColumnIndex:0];
            NSData *data = [rows dataForColumnIndex:1];
            cursor = messageID;
            if (messageID.length > 0 && data.length > 0) [batch addObject:@[messageID, data]];
        }
        if (db.lastErrorCode != SQLITE_OK && db.lastErrorCode != SQLITE_ROW && db.lastErrorCode != SQLITE_DONE) failure = db.lastError;
        [rows close];
        for (NSArray *row in batch) {
            if (failure != nil) break;
            NSData *resolved = nil;
            CHMessageProcessFlags flags = 0;
            CHMessageModel *model = [CHMessageModel modelWithWatchCachedData:row[1] mid:row[0] storage:storage uid:uid raw:&resolved flags:&flags];
            if (model != nil && resolved.length > 0) {
                if (![db executeUpdate:@"UPDATE messages SET raw=? WHERE mid=? AND raw=?;", resolved, row[0], row[1]]) failure = db.lastError;
            } else if ((flags & CHMessageProcessFlagBlocked) == CHMessageProcessFlagBlocked) {
                if (![db executeUpdate:@"DELETE FROM messages WHERE mid=? AND raw=?;", row[0], row[1]] ||
                    ![db executeUpdate:@"UPDATE channels SET mid=(SELECT MAX(mid) FROM messages WHERE cid=channels.cid) WHERE mid=?;", row[0]]) failure = db.lastError;
            } else if (flags & CHMessageProcessFlagNeedsKey) {
                needsKey = YES;
            }
        }
        if (!failure && cursor == nil && !needsKey) {
            if (![db executeUpdate:@"INSERT INTO options(key,value) VALUES('watch-encrypted-cache-repaired-v1',1) ON CONFLICT(key) DO UPDATE SET value=1;"]) failure = db.lastError;
        }
        if (failure || ![db commit]) {
            failure = failure ?: db.lastError;
            [db rollback];
        }
    }];
    if (error != nil) *error = failure;
    *pending = needsKey || failure != nil;
    return failure ? nil : cursor;
}

// Keep Watch browsing isolated from the existing iOS channel paging path.
- (void)loadWatchMessagesBeforeMID:(nullable NSString *)mid count:(NSUInteger)count completion:(CHWatchMessageLoadCompletion)completion {
    NSUInteger limit = MIN(MAX(count, 1), 32);
    dispatch_async(self.messageReadQueue, ^{
        if (self.closed) return;
        NSMutableArray *messages = [NSMutableArray new];
        __block NSString *cursor = nil;
        __block BOOL hasMore = NO;
        __block NSError *error = nil;
        void (^read)(FMDatabase *) = ^(FMDatabase *db) {
            if (self.closed) return;
            sqlite3_progress_handler(db.sqliteHandle, 2000, CHMessageReadCancelled, (__bridge void *)self);
            NSString *filter = mid.length > 0 ? @" AND m.mid<?" : @"";
            NSString *sql = [NSString stringWithFormat:@"SELECT m.mid,m.raw FROM messages m INNER JOIN channels c ON c.cid=m.cid WHERE IFNULL(c.hidden,0)=0 AND IFNULL(c.deleted,0)=0%@ ORDER BY m.mid DESC LIMIT ?;", filter];
            NSArray *arguments = mid.length > 0 ? @[mid, @(limit + 1)] : @[@(limit + 1)];
            FMResultSet *rows = [db executeQuery:sql withArgumentsInArray:arguments];
            if (!rows) error = db.lastError;
            NSUInteger scanned = 0;
            while ([rows next] && !self.closed) {
                if (scanned++ >= limit) { hasMore = YES; break; }
                cursor = [rows stringForColumnIndex:0];
                CHMessageModel *message = [CHMessageModel modelWithData:[rows dataForColumnIndex:1] mid:cursor];
                if (message) [messages addObject:message];
            }
            if (db.lastErrorCode != SQLITE_OK && db.lastErrorCode != SQLITE_ROW && db.lastErrorCode != SQLITE_DONE) error = db.lastError;
            [rows close];
            sqlite3_progress_handler(db.sqliteHandle, 0, NULL, NULL);
        };
        if (self.dsURL.isFileURL) {
            FMDatabase *db = [FMDatabase databaseWithURL:self.dsURL];
            if ([db openWithFlags:SQLITE_OPEN_READONLY]) {
                db.maxBusyRetryTimeInterval = 0.1;
                read(db);
            } else {
                error = db.lastError ?: [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
            }
            [db close];
        } else {
            [self.dbQueue inDatabase:read];
        }
        dispatch_main_async(^{
            if (!self.closed) completion(error ? @[] : messages.copy, error ? nil : cursor, !error && hasMore, error);
        });
    });
}
#endif

- (void)loadMessagesNearMID:(NSString *)mid channelID:(NSString *)cid count:(NSUInteger)count completion:(CHMessageLoadCompletion)completion {
    NSData *channel = [NSData dataFromBase64:cid] ?: [NSData dataFromHex:@kCHDefChanCode];
    NSNumber *limit = @(MIN(MAX(count, 1), 128));
    [self readMessagesWithSQL:@"SELECT mid,raw FROM (SELECT mid,raw FROM messages WHERE cid=? AND mid<=? ORDER BY mid DESC LIMIT ?) UNION ALL SELECT mid,raw FROM (SELECT mid,raw FROM messages WHERE cid=? AND mid>? ORDER BY mid ASC LIMIT ?) ORDER BY mid DESC;" arguments:@[channel, mid, limit, channel, mid, limit] reverse:NO completion:completion];
}

- (void)loadMessagesWithCID:(NSString *)cid from:(NSString *)from to:(NSString *)to count:(NSUInteger)count ascending:(BOOL)ascending completion:(CHMessageLoadCompletion)completion {
    NSData *channel = [NSData dataFromBase64:cid] ?: [NSData dataFromHex:@kCHDefChanCode];
    NSString *sql = ascending ? @"SELECT mid,raw FROM messages WHERE cid=? AND mid<? AND mid>? ORDER BY mid ASC LIMIT ?;" : @"SELECT mid,raw FROM messages WHERE cid=? AND mid<? AND mid>? ORDER BY mid DESC LIMIT ?;";
    [self readMessagesWithSQL:sql arguments:@[channel, from, to, @(MIN(MAX(count, 1), 128))] reverse:ascending completion:completion];
}

- (NSArray<CHMessageModel *> *)messagesNearMID:(NSString *)mid channelID:(NSString *)cid count:(NSUInteger)count {
    NSMutableArray *items = [NSMutableArray new];
    NSData *channel = [NSData dataFromBase64:cid];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:@"SELECT mid,raw FROM (SELECT mid,raw FROM messages WHERE cid=? AND mid<=? ORDER BY mid DESC LIMIT ?) UNION ALL SELECT mid,raw FROM (SELECT mid,raw FROM messages WHERE cid=? AND mid>? ORDER BY mid ASC LIMIT ?) ORDER BY mid DESC;", channel, mid, @(count), channel, mid, @(count)];
        while ([result next]) {
            CHMessageModel *model = [CHMessageModel modelWithData:[result dataForColumnIndex:1] mid:[result stringForColumnIndex:0]];
            if (model) [items addObject:model];
        }
        [result close];
    }];
    return items;
}

- (NSArray<CHMessageModel *> *)messagesAfterMID:(NSString *)mid channelID:(NSString *)cid count:(NSUInteger)count {
    NSMutableArray *items = [NSMutableArray new];
    NSData *channel = [NSData dataFromBase64:cid];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:@"SELECT mid,raw FROM messages WHERE cid=? AND mid>? ORDER BY mid ASC LIMIT ?;", channel, mid, @(count)];
        while ([result next]) {
            CHMessageModel *model = [CHMessageModel modelWithData:[result dataForColumnIndex:1] mid:[result stringForColumnIndex:0]];
            if (model) [items insertObject:model atIndex:0];
        }
        [result close];
    }];
    return items;
}

- (nullable CHMessageModel *)messageWithMID:(nullable NSString *)mid {
    __block CHMessageModel *model = nil;
    if (mid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            NSData *data = [db dataForQuery:@"SELECT `raw` FROM `messages` WHERE `mid`=? LIMIT 1;", mid];
            model = [CHMessageModel modelWithData:data mid:mid];
        }];
    }
    return model;
}

- (nullable CHMessageModel *)upsertMessageData:(NSData *)data nsDB:(id<CHKeyStorage, CHBlockedStorage>)nsDB uid:(NSString *)uid mid:(NSString *)mid checker:(BOOL (NS_NOESCAPE ^ _Nullable)(NSString * cid))checker flags:(CHUpsertMessageFlags *)pFlags {
    if (pFlags != nil) *pFlags = 0;
    if (mid.length == 0) return nil;
    NSData *raw = nil;
    CHMessageProcessFlags processFlags = 0;
    CHMessageModel *model = [CHMessageModel modelWithStorage:nsDB uid:uid mid:mid data:data raw:&raw flags:&processFlags];
    if (model == nil) {
        if (pFlags != nil && (processFlags & CHMessageProcessFlagBlocked) == CHMessageProcessFlagBlocked) {
            *pFlags = CHUpsertMessageFlagDiscarded;
        }
        return nil;
    }
    __block BOOL res = NO;
    __block CHUpsertMessageFlags flags = 0;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        if (![db beginTransaction]) return;
        NSData *ccid = model.channel;
        BOOL success = [db executeUpdate:@"INSERT OR IGNORE INTO `messages`(`mid`,`cid`,`from`,`raw`) VALUES(?,?,?,?);", mid, ccid, model.from, raw];
        BOOL inserted = success && db.changes > 0;
        FMResultSet *result = success ? [db executeQuery:@"SELECT `mid`,`deleted`,`hidden` FROM `channels` WHERE `cid`=? LIMIT 1;", ccid] : nil;
        success = success && result != nil;
        NSString *oldMid = nil;
        BOOL chanFound = NO;
        if (result.next) {
            oldMid = [result stringForColumnIndex:0];
            chanFound = ![result boolForColumnIndex:1] && ![result boolForColumnIndex:2];
        }
        [result close];
        if (success && !chanFound) {
            success = [db executeUpdate:@"INSERT INTO `channels`(`cid`,`mid`,`unread`) VALUES(?,?,0) ON CONFLICT(`cid`) DO UPDATE SET `deleted`=0,`hidden`=0;", ccid, mid];
            if (success) flags |= CHUpsertMessageFlagChannel;
        }
        if (success && inserted && !model.needNoAlert && checker != nil && checker(ccid.base64Code)) {
            success = [db executeUpdate:@"UPDATE `channels` SET `unread`=IFNULL(`unread`,0)+1 WHERE `cid`=?;", ccid];
            if (success) flags |= CHUpsertMessageFlagUnread | CHUpsertMessageFlagChannel;
        }
        if (success && (oldMid.length == 0 || [oldMid compare:mid] == NSOrderedAscending)) {
            success = [db executeUpdate:@"UPDATE `channels` SET `mid`=? WHERE `cid`=?;", mid, ccid];
            if (success) flags |= CHUpsertMessageFlagChannel;
        }
        if (success) res = [db commit];
        if (!res) [db rollback];
    }];
    if (res) [self.messageSearch requestIndexing];
    if (res && pFlags != nil) *pFlags = flags;
    return res ? model : nil;
}

- (NSArray<CHScriptModel *> *)loadScripts {
    __block NSMutableArray<CHScriptModel *> *scripts = [NSMutableArray new];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT `name`,`type`,`lastupdate` FROM `scripts` ORDER BY `lastupdate` DESC;"];
        while(res.next) {
            CHScriptModel *model = [CHScriptModel modelWithName:[res stringForColumnIndex:0] type:[res stringForColumnIndex:1] lastupdate:[res dateForColumnIndex:2]];
            if (model != nil) {
                [scripts addObject:model];
            }
        }
        [res close];
        [res setParentDB:nil];
    }];
    return scripts;
}

- (BOOL)insertScript:(CHScriptModel *)model {
    __block BOOL res = NO;
    if (model != nil && model.name.length > 0) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSDate *now = model.lastupdate ?: NSDate.now;
            res = [db executeUpdate:@"INSERT INTO `scripts`(`name`,`type`,`lastupdate`,`createtime`,`script`) VALUES(?,?,?,?,?);", model.name, model.type, now, now, model.content?:@""];
        }];
    }
    return res;
}

- (BOOL)deleteScript:(NSString *)name {
    __block BOOL res = YES;
    if (name.length > 0) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"DELETE FROM `scripts` WHERE `name`=? LIMIT 1;", name];
            res = YES;
        }];
    }
    return res;
}

- (nullable CHScriptModel *)scriptWithName:(nullable NSString *)name {
    __block CHScriptModel *model = nil;
    if (name.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *res = [db executeQuery:@"SELECT `type`,`lastupdate` FROM `scripts` WHERE `name`=? LIMIT 1;", name];
            while(res.next) {
                model = [CHScriptModel modelWithName:name type:[res stringForColumnIndex:0] lastupdate:[res dateForColumnIndex:1]];
            }
            [res close];
            [res setParentDB:nil];
        }];
    }
    return model;
}

- (NSString *)scriptContentWithName:(nullable NSString *)name type:(NSString *)type {
    __block NSString *content = nil;
    if (name.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            content = [db stringForQuery:@"SELECT `script` FROM `scripts` WHERE `name`=? AND `type`=? LIMIT 1;", name, type];
        }];
    }
    return content ?: @"";
}

- (BOOL)updateScriptContent:(NSString *)content name:(NSString *)name {
    __block BOOL res = YES;
    if (name.length > 0) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            res = [db executeUpdate:@"UPDATE `scripts` SET `script`=?,`lastupdate`=? WHERE `name`=? LIMIT 1;", content?: @"", NSDate.now, name];
        }];
    }
    return res;
}


@end
