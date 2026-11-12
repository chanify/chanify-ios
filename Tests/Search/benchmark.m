#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
#import "CHMessageSearch.h"
#import <sqlite3.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSUInteger count = argc > 1 ? strtoull(argv[1], NULL, 10) : 100000;
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"bench.sqlite"]];
        FMDatabase *db = [FMDatabase databaseWithURL:url]; [db open];
        [db executeStatements:@"PRAGMA journal_mode=WAL; CREATE TABLE messages(mid TEXT PRIMARY KEY,cid BLOB,raw BLOB); CREATE TABLE channels(cid BLOB PRIMARY KEY,name TEXT); CREATE TABLE message_search(id INTEGER PRIMARY KEY,mid TEXT UNIQUE NOT NULL,cid BLOB,title TEXT NOT NULL,text TEXT NOT NULL,normalized_title TEXT NOT NULL,normalized_text TEXT NOT NULL,version INTEGER NOT NULL); CREATE INDEX message_search_mid ON message_search(mid DESC); CREATE VIRTUAL TABLE message_search_fts USING fts5(title_tokens,text_tokens,content='',tokenize='ascii');"];
        [CHMessageSearch prepareTrackingInDatabase:db];
        [db executeUpdate:@"UPDATE message_search_meta SET value='' WHERE key='history_cursor';"];
        [db executeUpdate:@"INSERT INTO message_search_meta VALUES('index_version','1');"];
        db.shouldCacheStatements = YES;
        NSString *title = @"服务器状态更新 Service status";
        NSString *body = @"服务器连接成功。通知内容包含中文与 English，100% 完成，文件备份任务正常。This is a notification with a service health check and deployment update.";
        NSString *titleTokens = [CHMessageSearch tokensForText:title];
        NSString *bodyTokens = [CHMessageSearch tokensForText:body];
        NSString *rareBody = [body stringByAppendingString:@" 罕见故障 raremarker"];
        NSString *rareTokens = [CHMessageSearch tokensForText:rareBody];
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        [db beginTransaction];
        for (NSUInteger i = 1; i <= count; i++) {
            @autoreleasepool {
                NSString *mid = [NSString stringWithFormat:@"%016lx", (unsigned long)i];
                BOOL rare = i % 1000 == 0;
                [db executeUpdate:@"INSERT INTO messages VALUES(?,X'0801',X'00');", mid];
                [db executeUpdate:@"INSERT INTO message_search VALUES(?,?,X'0801',?,?,?,?,1);", @(i), mid, title, rare ? rareBody : body, [CHMessageSearch normalizedText:title], [CHMessageSearch normalizedText:rare ? rareBody : body]];
                [db executeUpdate:@"INSERT INTO message_search_fts(rowid,title_tokens,text_tokens) VALUES(?,?,?);", @(i), titleTokens, rare ? rareTokens : bodyTokens];
                if (i % 5000 == 0) { [db commit]; [db beginTransaction]; }
            }
        }
        [db executeUpdate:@"DELETE FROM message_search_pending;"];
        [db commit];
        [db executeUpdate:@"PRAGMA wal_checkpoint(TRUNCATE);"];
        printf("rows=%lu build=%.2fs database=%.1fMiB sqlite=%s\n", (unsigned long)count, CFAbsoluteTimeGetCurrent()-start, [[NSFileManager.defaultManager attributesOfItemAtPath:url.path error:nil] fileSize]/1048576.0, sqlite3_libversion()); fflush(stdout);
        CHMessageSearch *search = [[CHMessageSearch alloc] initWithURL:url extractor:^NSDictionary *(NSData *data, NSString *mid) { return nil; }];
        NSDate *readyDeadline = [NSDate dateWithTimeIntervalSinceNow:5];
        while (![[search valueForKey:@"ready"] boolValue] && readyDeadline.timeIntervalSinceNow > 0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
        if (![[search valueForKey:@"ready"] boolValue]) return 1;
        BOOL benchmarkFailed = NO;
        for (NSString *query in @[@"连", @"连接", @"服务器连接成功", @"raremarker", @"不存在的文本", @"status"]) {
            NSMutableArray *times = [NSMutableArray new];
            __block NSUInteger failures = 0;
            for (NSUInteger run = 0; run < 6; run++) {
                __block BOOL done = NO;
                CFAbsoluteTime began = CFAbsoluteTimeGetCurrent();
                [search search:query before:nil limit:30 completion:^(NSArray *items, BOOL more, BOOL incomplete, NSError *error) {
                    if (error) { failures++; fprintf(stderr,"query error %s: %s\n", query.UTF8String, error.description.UTF8String); }
                    done = YES;
                }];
                NSDate *end = [NSDate dateWithTimeIntervalSinceNow:5];
                while (!done && end.timeIntervalSinceNow > 0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
                if (!done) failures++;
                [times addObject:@((CFAbsoluteTimeGetCurrent()-began)*1000)];
            }
            if (failures) benchmarkFailed = YES;
            [times sortUsingSelector:@selector(compare:)];
            printf("query=%s median=%.1fms max=%.1fms missing_callbacks=%lu\n",query.UTF8String,[times[times.count/2] doubleValue],[times.lastObject doubleValue],(unsigned long)failures); fflush(stdout);
        }
        [search close]; [db close];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        [NSFileManager.defaultManager removeItemAtPath:directory error:nil];
        if (benchmarkFailed) return 1;
    }
}
