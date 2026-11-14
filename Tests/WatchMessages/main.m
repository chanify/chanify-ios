#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHMessageModel.h"
#import "CHNodeModel.h"
#import "CHScriptModel.h"
#import <FMDB/FMDB.h>
#import <sqlite3.h>

static void check(BOOL value, NSString *message) {
    if (!value) { NSLog(@"FAIL: %@", message); exit(1); }
}

// Only decoding and unrelated model construction are replaced. Storage,
// transactions, SQL cursors, read queues and account scoping are production code.
@interface CHMessageModel ()
@property (nonatomic, readwrite, strong) NSString *mid;
@end
@implementation CHMessageModel
+ (instancetype)modelWithData:(NSData *)data mid:(NSString *)mid {
    if (!data.length || (((const char *)data.bytes)[0] == '!' || ((const char *)data.bytes)[0] == 'e')) return nil;
    CHMessageModel *message = [self new]; message.mid = mid; return message;
}
+ (instancetype)modelWithStorage:(id)storage uid:(NSString *)uid mid:(NSString *)mid data:(NSData *)data raw:(NSData **)raw flags:(CHMessageProcessFlags *)flags {
    if (flags) *flags = 0;
    if (data.length && ((const char *)data.bytes)[0] == '#') {
        if (flags) *flags = CHMessageProcessFlagBlocked;
        return nil;
    }
    if (raw) *raw = data;
    return [self modelWithData:data mid:mid];
}
+ (instancetype)modelWithWatchCachedData:(NSData *)data mid:(NSString *)mid storage:(id)storage uid:(NSString *)uid raw:(NSData **)raw flags:(CHMessageProcessFlags *)flags {
    *flags = 0; *raw = nil;
    if (((const char *)data.bytes)[0] == '#') { *flags = CHMessageProcessFlagBlocked; return nil; }
    if (((const char *)data.bytes)[0] != 'e') return nil;
    if (![storage keyForUID:[uid stringByAppendingString:@".node"]]) { *flags = CHMessageProcessFlagNeedsKey; return nil; }
    *raw = [NSData dataWithBytes:"x" length:1];
    return [self modelWithData:*raw mid:mid];
}
- (NSData *)channel { return [NSData dataFromHex:@"0801"]; }
- (NSString *)from { return @"synthetic-node"; }
- (BOOL)needNoAlert { return NO; }
@end
@implementation CHNodeModel @end
@implementation CHChannelModel @end
@implementation CHScriptModel @end
@implementation NSData (TestEncoding)
+ (instancetype)dataFromHex:(NSString *)text {
    if (!text) return nil;
    NSMutableData *data = [NSMutableData new];
    for (NSUInteger i = 0; i + 1 < text.length; i += 2) {
        unsigned value = 0;
        [[NSScanner scannerWithString:[text substringWithRange:NSMakeRange(i, 2)]] scanHexInt:&value];
        uint8_t byte = value; [data appendBytes:&byte length:1];
    }
    return data;
}
+ (instancetype)dataFromBase64:(NSString *)text { return [[NSData alloc] initWithBase64EncodedString:text options:0]; }
- (NSString *)base64Code { return [self base64EncodedStringWithOptions:0]; }
@end
@implementation NSURL (TestProtection)
- (void)setDataProtoction:(NSString *)level {}
@end

static FMDatabaseQueue *queue(id source) { return [source valueForKey:@"dbQueue"]; }
static NSString *mid(NSUInteger number) { return [NSString stringWithFormat:@"%016lx", (unsigned long)number]; }
static NSData *raw(const char *value) { return [NSData dataWithBytes:value length:1]; }

static NSDictionary *page(CHUserDataSource *source, NSString *cursor, NSUInteger count) {
    __block NSDictionary *value = nil;
    [source loadWatchMessagesBeforeMID:cursor count:count completion:^(NSArray *messages, NSString *next, BOOL more, NSError *error) {
        check(NSThread.isMainThread, @"paging completes on the main thread");
        value = @{@"messages": messages, @"cursor": next ?: @"", @"more": @(more), @"error": @(error != nil)};
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while (!value && deadline.timeIntervalSinceNow > 0) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }
    check(value != nil, @"paging completes without blocking the UI thread");
    return value;
}

int main(int argc, const char **argv) { @autoreleasepool {
    check(argc == 2, @"isolated scratch path supplied");
    NSString *directory = [NSString stringWithUTF8String:argv[1]];
    CHUserDataSource *source = [CHUserDataSource dataSourceWithURL:[NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"paging.db"]]];
    check([page(source, nil, 20)[@"messages"] count] == 0, @"empty recent history");
    [queue(source) inDatabase:^(FMDatabase *db) {
        for (NSUInteger i = 1; i <= 45; i++) {
            check([db executeUpdate:@"INSERT INTO messages(mid,cid,raw) VALUES(?,X'0801',?);", mid(i), raw(i >= 44 ? "!" : "x")], @"insert synthetic message");
        }
        check([db executeStatements:@"INSERT INTO channels(cid,hidden) VALUES(X'0802',1); INSERT INTO channels(cid,deleted) VALUES(X'0803',1);"], @"insert hidden and deleted channels");
        check([db executeUpdate:@"INSERT INTO messages(mid,cid,raw) VALUES(?,X'0802',?);", mid(99), raw("x")], @"hidden channel fixture");
        check([db executeUpdate:@"INSERT INTO messages(mid,cid,raw) VALUES(?,X'0803',?);", mid(98), raw("x")], @"deleted channel fixture");
    }];
    NSDictionary *first = page(source, nil, 2);
    check([first[@"messages"] count] == 0 && [first[@"more"] boolValue] && [first[@"cursor"] isEqual:mid(44)], @"corrupt rows advance cursor without ending history or revealing hidden channels");
    NSDictionary *second = page(source, first[@"cursor"], 20);
    NSArray<CHMessageModel *> *secondMessages = second[@"messages"];
    check(secondMessages.count == 20 && [secondMessages.firstObject.mid isEqual:mid(43)] && [secondMessages.lastObject.mid isEqual:mid(24)] && [second[@"more"] boolValue], @"newest-first exclusive cursor");
    NSDictionary *third = page(source, second[@"cursor"], 20);
    NSArray<CHMessageModel *> *thirdMessages = third[@"messages"];
    check(thirdMessages.count == 20 && [thirdMessages.firstObject.mid isEqual:mid(23)] && [thirdMessages.lastObject.mid isEqual:mid(4)], @"next page has no overlap");
    NSDictionary *last = page(source, third[@"cursor"], 20);
    check([last[@"messages"] count] == 3 && ![last[@"more"] boolValue], @"last page detection");
    check([page(source, nil, 1000)[@"cursor"] isEqual:mid(14)], @"Watch page size is bounded to 32 raw rows");
    check([page(source, nil, 0)[@"cursor"] isEqual:mid(45)], @"zero page size is safely clamped");
    [queue(source) inDatabase:^(FMDatabase *db) { check([db executeStatements:@"DROP TABLE messages;"], @"read error fixture"); }];
    check([page(source, nil, 20)[@"error"] boolValue], @"read errors are reported instead of silently appearing empty");
    dispatch_queue_t readQueue = [source valueForKey:@"messageReadQueue"];
    dispatch_suspend(readQueue);
    __block BOOL callbackAfterClose = NO;
    [source loadWatchMessagesBeforeMID:nil count:20 completion:^(NSArray *messages, NSString *cursor, BOOL more, NSError *error) { callbackAfterClose = YES; }];
    [source close];
    dispatch_resume(readQueue);
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.03]];
    check(!callbackAfterClose, @"closed account cancels queued page delivery");
    puts("PASS: Watch recent paging, corrupt rows, visibility, cursor bounds, read errors and close cancellation");

    CHNSDataSource *inbox = [CHNSDataSource dataSourceWithURL:[NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"inbox.db"]]];
    CHUserDataSource *destination = [CHUserDataSource dataSourceWithURL:[NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"destination.db"]]];
    [queue(inbox) inDatabase:^(FMDatabase *db) {
        for (NSUInteger i = 1; i <= 35; i++) check([db executeUpdate:@"INSERT INTO msgs(uid,mid,data) VALUES('synthetic',?,?);", mid(i), raw(i == 3 ? "#" : "x")], @"inbox packet fixture");
        check([db executeUpdate:@"INSERT INTO msgs(uid,mid,data) VALUES('other',?,?);", mid(1), raw("x")], @"other account inbox fixture");
    }];
    [queue(destination) inDatabase:^(FMDatabase *db) {
        check([db executeStatements:@"CREATE TRIGGER reject_write BEFORE INSERT ON messages WHEN NEW.mid='0000000000000002' BEGIN SELECT RAISE(FAIL,'synthetic write failure'); END;"], @"transaction failure fixture");
    }];
    NSString *cursor = @"";
    NSUInteger batches = 0, retained = 0;
    while (YES) {
        NSMutableArray *committed = [NSMutableArray new];
        __block NSUInteger scanned = 0;
        NSError *error = nil;
        NSString *next = [inbox enumerateWatchMessagesWithUID:@"synthetic" afterMID:cursor limit:16 error:&error block:^(FMDatabase *db, NSString *messageID, NSData *data) {
            scanned++;
            CHUpsertMessageFlags flags = 0;
            CHMessageModel *message = [destination upsertMessageData:data nsDB:[CHTempNSDatasource datasourceFromDB:db] uid:@"synthetic" mid:messageID checker:nil flags:&flags];
            if (message || (flags & CHUpsertMessageFlagDiscarded)) [committed addObject:messageID];
        }];
        check(!error && scanned <= 16, @"bounded production inbox query");
        retained += scanned - committed.count;
        [inbox removeMessages:committed uid:@"synthetic"];
        if (!next) break;
        cursor = next; batches++;
        check(batches <= 3, @"failed packets do not cause an infinite pass");
    }
    check(batches == 3 && retained == 1 && destination.unreadSumAllChannel == 0, @"failure retained without changing unread counters");
    [queue(destination) inDatabase:^(FMDatabase *db) {
        check([db intForQuery:@"SELECT COUNT(*) FROM messages;"] == 33, @"only successful messages committed");
        check([db executeStatements:@"DROP TRIGGER reject_write;"], @"allow retry");
    }];
    __block NSUInteger retried = 0;
    __block CHUpsertMessageFlags retryFlags = 0;
    [inbox enumerateWatchMessagesWithUID:@"synthetic" afterMID:@"" limit:16 error:nil block:^(FMDatabase *db, NSString *messageID, NSData *data) {
        check([messageID isEqual:mid(2)], @"only failed packet remains in this account");
        check([destination upsertMessageData:data nsDB:[CHTempNSDatasource datasourceFromDB:db] uid:@"synthetic" mid:messageID checker:nil flags:&retryFlags] != nil, @"failed commit retries successfully");
        retried++;
    }];
    check(retried == 1, @"exactly one recoverable failure");
    [destination upsertMessageData:raw("x") nsDB:inbox uid:@"synthetic" mid:mid(2) checker:nil flags:&retryFlags];
    [queue(destination) inDatabase:^(FMDatabase *db) { check([db intForQuery:@"SELECT COUNT(*) FROM messages;"] == 34, @"repeated successful write is idempotent"); }];
    [queue(destination) inDatabase:^(FMDatabase *db) {
        check([db executeUpdate:@"INSERT INTO messages(mid,cid,raw) VALUES(?,X'0801',?);", mid(40), raw("e")], @"legacy encrypted cache fixture");
        check([db executeUpdate:@"INSERT INTO messages(mid,cid,raw) VALUES(?,X'0801',?);", mid(41), raw("e")], @"second legacy cache fixture");
        check([db executeUpdate:@"INSERT INTO messages(mid,cid,raw) VALUES(?,X'0801',?);", mid(42), raw("#")], @"blocked legacy cache fixture");
        check([db executeUpdate:@"UPDATE channels SET mid=?,unread=7 WHERE cid=X'0801';", mid(42)], @"preserve unread and channel metadata");
    }];
    BOOL pending = NO;
    NSError *repairError = nil;
    cursor = @"";
    while (YES) {
        NSString *next = [destination repairWatchMessagesAfterMID:cursor storage:inbox uid:@"synthetic" limit:16 pending:&pending error:&repairError];
        check(!repairError, @"legacy repair can defer missing keys");
        if (!next) break;
        cursor = next;
    }
    check(pending && [destination messageWithMID:mid(40)] == nil && destination.unreadSumAllChannel == 7, @"missing keys retain hidden legacy cache without altering unread");
    [queue(destination) inDatabase:^(FMDatabase *db) {
        check([db intForQuery:@"SELECT COUNT(*) FROM messages WHERE mid=?;", mid(42)] == 0, @"blocked legacy cache is discarded");
        check([[db stringForQuery:@"SELECT mid FROM channels WHERE cid=X'0801';"] isEqual:mid(41)], @"blocked latest message updates channel pointer");
        check([db intForQuery:@"SELECT value FROM options WHERE key='watch-encrypted-cache-repaired-v1';"] == 0, @"pending repair is not marked complete");
        check([db executeStatements:@"CREATE TRIGGER reject_repair BEFORE UPDATE OF raw ON messages WHEN NEW.mid='0000000000000028' BEGIN SELECT RAISE(FAIL,'synthetic repair failure'); END;"], @"repair failure fixture");
    }];
    [inbox updateKey:raw("k") uid:@"synthetic.node"];
    pending = NO; cursor = @"";
    while (YES) {
        NSString *next = [destination repairWatchMessagesAfterMID:cursor storage:inbox uid:@"synthetic" limit:16 pending:&pending error:&repairError];
        if (repairError || !next) break;
        cursor = next;
    }
    check(repairError != nil && pending && [destination messageWithMID:mid(40)] == nil, @"failed legacy update rolls back and remains retryable");
    [queue(destination) inDatabase:^(FMDatabase *db) { check([db executeStatements:@"DROP TRIGGER reject_repair;"], @"allow legacy repair retry"); }];
    pending = NO; cursor = @"";
    while (YES) {
        NSString *next = [destination repairWatchMessagesAfterMID:cursor storage:inbox uid:@"synthetic" limit:16 pending:&pending error:&repairError];
        check(!repairError, @"legacy repair retry succeeds");
        if (!next) break;
        cursor = next;
    }
    check(!pending && [destination messageWithMID:mid(40)] != nil && [destination messageWithMID:mid(41)] != nil && destination.unreadSumAllChannel == 7, @"legacy cache resolves in place after key arrives without unread changes");
    [queue(destination) inDatabase:^(FMDatabase *db) {
        check([db intForQuery:@"SELECT value FROM options WHERE key='watch-encrypted-cache-repaired-v1';"] == 1, @"successful full scan persists completion");
    }];
    check([destination repairWatchMessagesAfterMID:@"" storage:inbox uid:@"synthetic" limit:16 pending:&pending error:&repairError] == nil && !repairError, @"completed recovery is not rescanned on each notification");
    FMDatabase *pageReader = [FMDatabase databaseWithURL:destination.dsURL];
    check([pageReader openWithFlags:SQLITE_OPEN_READONLY] && [pageReader beginDeferredTransaction], @"concurrent page reader starts");
    check([pageReader intForQuery:@"SELECT value FROM options WHERE key='watch-encrypted-cache-repaired-v1';"] == 1, @"page reader holds a snapshot");
    pending = NO; repairError = nil;
    check([destination repairWatchMessagesAfterMID:@"" storage:inbox uid:@"synthetic" limit:16 pending:&pending error:&repairError] == nil && !pending && !repairError, @"completed repair needs no write lock while page reader is active");
    [pageReader rollback]; [pageReader close];
    puts("PASS: completed Watch repair skips write locking during concurrent reads");
    puts("PASS: Watch legacy cache key delay, rollback/retry, blocklist, channel pointers, unread preservation and persisted completion");
    [queue(inbox) inDatabase:^(FMDatabase *db) {
        check([db intForQuery:@"SELECT COUNT(*) FROM msgs WHERE uid='other';"] == 1, @"other account inbox remains untouched");
        check([db executeStatements:@"DROP TABLE msgs;"], @"inbox read failure fixture");
    }];
    NSError *inboxError = nil;
    [inbox enumerateWatchMessagesWithUID:@"synthetic" afterMID:@"" limit:16 error:&inboxError block:^(FMDatabase *db, NSString *messageID, NSData *data) {}];
    check(inboxError != nil, @"inbox query failure is surfaced");
    [destination close]; [inbox close];
    puts("PASS: Watch production inbox batches, transaction rollback/retry, explicit discard, idempotency and account scoping");
} return 0; }
