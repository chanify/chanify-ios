#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
#import "CHMessageSearch.h"
#import <sqlite3.h>

static void Check(BOOL ok, NSString *message) {
    if (!ok) { fprintf(stderr, "FAIL: %s\n", message.UTF8String); exit(1); }
}
static BOOL Until(BOOL (^predicate)(void)) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:10];
    do {
        if (predicate()) return YES;
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    } while (end.timeIntervalSinceNow > 0);
    return NO;
}
static NSArray *Search(CHMessageSearch *search, NSString *query, NSString *before, NSUInteger limit, BOOL *more) {
    __block BOOL done = NO;
    __block NSArray *items;
    __block NSError *failure;
    __block BOOL hasMore = NO;
    [search search:query before:before limit:limit completion:^(NSArray *results, BOOL next, BOOL incomplete, NSError *error) {
        items = results; failure = error; hasMore = next; done = YES;
    }];
    Check(Until(^BOOL{ return done; }), @"search callback");
    Check(!failure, [NSString stringWithFormat:@"query %@: %@", query, failure]);
    if (more) *more = hasMore;
    return items;
}
static NSDictionary *Extract(NSData *data, NSString *mid) {
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}
static void Insert(FMDatabase *db, NSString *mid, NSString *title, NSString *text) {
    NSData *raw = [NSJSONSerialization dataWithJSONObject:@{ @"title":title, @"text":text } options:0 error:nil];
    Check([db executeUpdate:@"INSERT OR IGNORE INTO messages VALUES(?,X'0801','test',?);", mid, raw], @"insert source");
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"messages.sqlite"]];
        FMDatabase *db = [FMDatabase databaseWithURL:url];
        Check([db open], @"open fixture");
        Check([db executeStatements:@"PRAGMA journal_mode=WAL; PRAGMA user_version=3; CREATE TABLE messages(mid TEXT PRIMARY KEY,cid BLOB,`from` TEXT,raw BLOB); CREATE TABLE channels(cid BLOB PRIMARY KEY,name TEXT); INSERT INTO channels VALUES(X'0801','Test channel');"], @"fixture schema");
        Insert(db, @"0000000000000001", @"历史连接失败", @"old body");
        NSData *original = [db dataForQuery:@"SELECT raw FROM messages WHERE mid='0000000000000001';"];
        Check([CHMessageSearch prepareTrackingInDatabase:db], @"upgrade");
        Check([CHMessageSearch prepareTrackingInDatabase:db], @"idempotent upgrade");
        Check(db.userVersion == 4 && [db intForQuery:@"SELECT count(*) FROM messages;"] == 1, @"version and row preservation");
        Check([original isEqualToData:[db dataForQuery:@"SELECT raw FROM messages WHERE mid='0000000000000001';"]], @"raw preservation");
        Check([db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0, @"no eager history registration");
        Insert(db, @"0000000000000003", @"连接正常", @"Hello WORLD 100% _ AND OR \"quote\" 😀 café");
        Insert(db, @"0000000000000002", @"延迟到达", @"连接失败");
        Insert(db, @"0000000000000002", @"duplicate", @"ignored");
        Check([db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 2, @"duplicates and late IDs");
        CHMessageSearch *search = [[CHMessageSearch alloc] initWithURL:url extractor:^NSDictionary *(NSData *data, NSString *mid) { return Extract(data, mid); }];
        [search setHistoryIndexingEnabled:YES];
        Check(Until(^BOOL{ return [db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0 && [db intForQuery:@"SELECT count(*) FROM message_search;"] == 3; }), @"new messages and history indexed");
        BOOL more = NO;
        NSArray *items = Search(search, @"连接", nil, 1, &more);
        Check(items.count == 1 && more && [items[0][@"mid"] isEqual:@"0000000000000003"], @"descending first page");
        items = Search(search, @"连接", items.lastObject[@"mid"], 10, NULL);
        Check(items.count == 2 && [items[0][@"mid"] isEqual:@"0000000000000002"], @"cursor pagination");
        for (NSString *query in @[@"连", @"失败", @"world", @"100%", @"_", @"AND OR", @"\"quote\"", @"😀", @"cafe\u0301"]) {
            Check(Search(search, query, nil, 30, NULL).count > 0, [@"literal/Unicode match " stringByAppendingString:query]);
        }
        Check(Search(search, @"missing phrase", nil, 30, NULL).count == 0, @"no result");
        Insert(db, @"0000000000000004", @"ab bc", @"other");
        [search requestIndexing];
        Check(Until(^BOOL{ return [db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0; }), @"candidate indexed");
        Check(Search(search, @"abc", nil, 30, NULL).count == 0, @"bigram false positives filtered");
        // The source transaction cannot succeed without its durable task.
        [search setActive:NO];
        Check([db executeStatements:@"CREATE TRIGGER reject_pending BEFORE INSERT ON message_search_pending BEGIN SELECT RAISE(ABORT,'task failure'); END;"], @"inject pending failure");
        Check(![db executeUpdate:@"INSERT INTO messages VALUES('failed-task',X'0801','test',X'00');"], @"source reports failed tracking");
        Check([db intForQuery:@"SELECT count(*) FROM messages WHERE mid='failed-task';"] == 0, @"failed tracking rolls source back");
        Check([db executeStatements:@"DROP TRIGGER reject_pending;"], @"remove pending fault");
        [search setActive:YES];
        // A persisted task survives the first worker's shutdown.
        [search close];
        Insert(db, @"0000000000000005", @"restart marker", @"restart body");
        search = [[CHMessageSearch alloc] initWithURL:url extractor:^NSDictionary *(NSData *data, NSString *mid) { return Extract(data, mid); }];
        Check(Until(^BOOL{ return [db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0; }), @"restart recovery");
        Check(Search(search, @"restart", nil, 30, NULL).count == 1, @"recovered message searchable");
        // Deletion is immediately authoritative even before asynchronous index cleanup.
        [search setActive:NO];
        Check([db executeUpdate:@"DELETE FROM messages WHERE mid='0000000000000005';"], @"delete source");
        Check(Search(search, @"restart", nil, 30, NULL).count == 0, @"stale FTS result hidden");
        [search setActive:YES];
        Check(Until(^BOOL{ return [db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0; }), @"delete cleanup");
        // Failed FTS maintenance must not affect a source write or its durable task.
        [search setActive:NO];
        Check([db executeStatements:@"CREATE TRIGGER reject_search BEFORE INSERT ON message_search BEGIN SELECT RAISE(ABORT,'test index failure'); END;"], @"inject index failure");
        Insert(db, @"0000000000000006", @"safe source", @"kept raw");
        [search setActive:YES];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
        Check([db intForQuery:@"SELECT count(*) FROM messages WHERE mid='0000000000000006';"] == 1, @"source survives FTS failure");
        Check([db intForQuery:@"SELECT count(*) FROM message_search_pending WHERE mid='0000000000000006';"] == 1, @"failed task retained");
        [search close];
        Check([db executeStatements:@"DROP TRIGGER reject_search;"], @"remove fault");
        search = [[CHMessageSearch alloc] initWithURL:url extractor:^NSDictionary *(NSData *data, NSString *mid) { return Extract(data, mid); }];
        Check(Until(^BOOL{ return [db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0; }), @"retry after restart");
        Check(Search(search, @"safe source", nil, 30, NULL).count == 1, @"retry indexed");
        // Rebuild touches only derived tables and repopulates recent messages.
        [search rebuildIndex];
        Check(Until(^BOOL{ return [db intForQuery:@"SELECT CAST(value AS INTEGER) FROM message_search_meta WHERE key='rebuild_generation';"] == 1 && [db tableExists:@"message_search"] && [db intForQuery:@"SELECT count(*) FROM message_search;"] == 5 && [db intForQuery:@"SELECT count(*) FROM message_search_pending;"] == 0; }), @"rebuild recent index");
        Check(Search(search, @"safe source", nil, 30, NULL).count == 1, @"search after rebuild");
        Check([db executeUpdate:@"INSERT INTO message_search_fts(message_search_fts) VALUES('integrity-check');"], @"FTS integrity");
        Check([[db stringForQuery:@"PRAGMA quick_check;"] isEqual:@"ok"], @"source database integrity");
        Check([original isEqualToData:[db dataForQuery:@"SELECT raw FROM messages WHERE mid='0000000000000001';"]], @"raw unchanged after indexing");
        [search close];
        [db close];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        [NSFileManager.defaultManager removeItemAtPath:directory error:nil];
        FMDatabase *failedMigration = [FMDatabase databaseWithPath:nil];
        [failedMigration open];
        Check([failedMigration executeStatements:@"PRAGMA user_version=3; CREATE TABLE messages(mid TEXT PRIMARY KEY,raw BLOB); INSERT INTO messages VALUES('kept',X'1234'); CREATE VIEW message_search_pending AS SELECT mid FROM messages;"], @"failed upgrade fixture");
        Check(![CHMessageSearch prepareTrackingInDatabase:failedMigration] && failedMigration.userVersion == 3, @"failed schema upgrade does not advance version");
        Check([[failedMigration dataForQuery:@"SELECT raw FROM messages WHERE mid='kept';"] isEqual:[NSData dataWithBytes:"\x12\x34" length:2]], @"failed upgrade preserves raw");
        [failedMigration close];
        puts("PASS: migration/rollback/raw preservation, durable tasks/restart, Unicode/literal/short queries, pagination, exact filter, delete, failed index/retry/rebuild, integrity");
    }
    return 0;
}
