#import "CHMessageSearch.h"
#import <FMDB/FMDB.h>
#import <sqlite3.h>
#import <os/lock.h>

static int CHSearchDeadline(void *context);
static char CHSearchWorkerKey;
static char CHSearchReaderKey;

static const NSInteger CHSearchSchemaVersion = 1;
static const NSUInteger CHSearchBatchSize = 12;
static const NSUInteger CHSearchBatchBytes = 512 * 1024;

@interface CHMessageSearch () {
    os_unfair_lock _stateLock;
    NSUInteger _generation;
    BOOL _closed;
    BOOL _active;
    BOOL _scheduled;
    sqlite3 *_readerHandle;
}
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> * (^extractor)(NSData *, NSString *);
@property (nonatomic, strong) dispatch_queue_t worker;
@property (nonatomic, strong) dispatch_queue_t queryQueue;
@property (nonatomic, strong) FMDatabase *writer;
@property (nonatomic, strong) FMDatabase *reader;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic) BOOL historyIndexingEnabled;
@property (atomic) BOOL ready;
@property (atomic) BOOL failed;
@property (nonatomic) CFAbsoluteTime lastSearch;
@end

@implementation CHMessageSearch

+ (BOOL)prepareTrackingInDatabase:(FMDatabase *)db {
    // No FTS dependency in these triggers: older writers can still save/delete messages.
    if (db.userVersion > 4 || ![db beginTransaction]) return NO;
    BOOL ok = [db executeStatements:@"CREATE TABLE IF NOT EXISTS message_search_pending(mid TEXT PRIMARY KEY);"
        "CREATE TABLE IF NOT EXISTS message_search_meta(key TEXT PRIMARY KEY,value TEXT);"
        "INSERT OR IGNORE INTO message_search_meta(key,value) SELECT 'history_cursor',COALESCE(MAX(mid),'') FROM messages;"
        "CREATE TRIGGER IF NOT EXISTS message_search_insert AFTER INSERT ON messages BEGIN "
        "INSERT OR IGNORE INTO message_search_pending(mid) VALUES(new.mid); END;"
        "CREATE TRIGGER IF NOT EXISTS message_search_delete AFTER DELETE ON messages BEGIN "
        "INSERT OR IGNORE INTO message_search_pending(mid) VALUES(old.mid); END;"];
    ok = ok && [db tableExists:@"message_search_pending"] && [db columnExists:@"mid" inTableWithName:@"message_search_pending"]
        && [db tableExists:@"message_search_meta"] && [db columnExists:@"value" inTableWithName:@"message_search_meta"];
    if (ok) ok = [db executeUpdate:@"PRAGMA user_version=4;"];
    if (ok) ok = [db commit];
    if (!ok) [db rollback];
    return ok;
}

+ (NSString *)normalizedText:(NSString *)text {
    return [text precomposedStringWithCanonicalMapping].lowercaseString;
}

+ (NSArray<NSString *> *)characters:(NSString *)text {
    NSMutableArray *items = [NSMutableArray new];
    // UTF-32 scalars keep substring matching independent of grapheme boundaries.
    NSData *data = [text dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
    const uint8_t *bytes = data.bytes;
    for (NSUInteger i = 0; i + 3 < data.length; i += 4) {
        uint32_t scalar = bytes[i] | ((uint32_t)bytes[i+1] << 8) | ((uint32_t)bytes[i+2] << 16) | ((uint32_t)bytes[i+3] << 24);
        [items addObject:[NSString stringWithFormat:@"%x", scalar]];
    }
    return items;
}

+ (NSString *)tokensForText:(NSString *)text {
    NSArray *characters = [self characters:[self normalizedText:text]];
    NSMutableOrderedSet *tokens = [NSMutableOrderedSet new];
    for (NSUInteger i = 0; i < characters.count; i++) {
        [tokens addObject:[@"u" stringByAppendingString:characters[i]]];
        if (i > 0) [tokens addObject:[NSString stringWithFormat:@"b%@z%@", characters[i-1], characters[i]]];
    }
    return [tokens.array componentsJoinedByString:@" "];
}

+ (NSString *)matchForText:(NSString *)text {
    NSArray *characters = [self characters:text];
    NSMutableOrderedSet *tokens = [NSMutableOrderedSet new];
    if (characters.count == 1) [tokens addObject:[@"u" stringByAppendingString:characters[0]]];
    for (NSUInteger i = 1; i < characters.count; i++) {
        [tokens addObject:[NSString stringWithFormat:@"b%@z%@", characters[i-1], characters[i]]];
    }
    NSString *match = [tokens.array componentsJoinedByString:@" AND "];
    return [NSString stringWithFormat:@"(title_tokens : (%@)) OR (text_tokens : (%@))", match, match];
}

- (instancetype)initWithURL:(NSURL *)url extractor:(NSDictionary<NSString *,NSString *> * _Nullable (^)(NSData *, NSString *))extractor {
    if (self = [super init]) {
        _stateLock = OS_UNFAIR_LOCK_INIT;
        _url = url;
        _extractor = [extractor copy];
        _worker = dispatch_queue_create("net.chanify.search.index", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0));
        _queryQueue = dispatch_queue_create("net.chanify.search.query", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0));
        dispatch_queue_set_specific(_worker, &CHSearchWorkerKey, (__bridge void *)self, NULL);
        dispatch_queue_set_specific(_queryQueue, &CHSearchReaderKey, (__bridge void *)self, NULL);
        _active = YES;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _worker);
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), 5 * NSEC_PER_SEC, NSEC_PER_SEC);
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(_timer, ^{ [weakSelf requestIndexing]; });
        dispatch_resume(_timer);
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didBecomeActive:) name:@"UIApplicationDidBecomeActiveNotification" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didEnterBackground:) name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
        [self requestIndexing];
    }
    return self;
}

- (void)didBecomeActive:(NSNotification *)notification { [self setActive:YES]; }
- (void)didEnterBackground:(NSNotification *)notification { [self setActive:NO]; }

- (BOOL)isActive {
    os_unfair_lock_lock(&_stateLock);
    BOOL active = _active && !_closed;
    os_unfair_lock_unlock(&_stateLock);
    return active;
}

- (void)setActive:(BOOL)active {
    os_unfair_lock_lock(&_stateLock);
    _active = active;
    os_unfair_lock_unlock(&_stateLock);
    if (active) [self requestIndexing];
    else [self cancelSearch];
}

- (BOOL)openWriter {
    if (self.failed) return NO;
    if (self.ready) return YES;
    self.writer = [FMDatabase databaseWithURL:self.url];
    if (![self.writer open]) return NO;
    self.writer.maxBusyRetryTimeInterval = 0.05;
    FMDatabase *db = self.writer;
    if (![db beginTransaction]) return NO;
    // Contentless FTS avoids storing token strings twice. No FTS trigger runs in message writes.
    BOOL ok = [db executeStatements:@"CREATE TABLE IF NOT EXISTS message_search("
        "id INTEGER PRIMARY KEY,mid TEXT UNIQUE NOT NULL,cid BLOB,title TEXT NOT NULL,text TEXT NOT NULL,"
        "normalized_title TEXT NOT NULL,normalized_text TEXT NOT NULL,version INTEGER NOT NULL);"
        "CREATE VIRTUAL TABLE IF NOT EXISTS message_search_fts USING fts5(title_tokens,text_tokens,content='',tokenize='ascii');"
        "CREATE INDEX IF NOT EXISTS message_search_mid ON message_search(mid DESC);"];
    if (ok) ok = [db executeUpdate:@"INSERT OR IGNORE INTO message_search_meta(key,value) VALUES('index_version',?);", @(CHSearchSchemaVersion).stringValue];
    NSString *version = ok ? [db stringForQuery:@"SELECT value FROM message_search_meta WHERE key='index_version';"] : nil;
    ok = ok && version.integerValue == CHSearchSchemaVersion;
    if (ok) ok = [db commit];
    if (!ok) { [db rollback]; self.failed = YES; return NO; }
    self.ready = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isActive]) [NSNotificationCenter.defaultCenter postNotificationName:@"CHMessageSearchDidUpdate" object:self];
    });
    return YES;
}

- (void)setHistoryIndexingEnabled:(BOOL)enabled {
    dispatch_async(self.worker, ^{ self->_historyIndexingEnabled = enabled; });
    [self requestIndexing];
}

- (void)scheduleIndexingAfter:(NSTimeInterval)delay {
    os_unfair_lock_lock(&_stateLock);
    BOOL schedule = !_scheduled && !_closed && _active;
    if (schedule) _scheduled = YES;
    os_unfair_lock_unlock(&_stateLock);
    if (!schedule) return;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), self.worker, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        os_unfair_lock_lock(&self->_stateLock);
        self->_scheduled = NO;
        os_unfair_lock_unlock(&self->_stateLock);
        [self indexBatch];
    });
}

- (void)requestIndexing { [self scheduleIndexingAfter:0]; }

- (void)rebuildIndex {
    dispatch_async(self.worker, ^{
        if (![self isActive]) return;
        if (!self.writer) self.writer = [FMDatabase databaseWithURL:self.url];
        if (![self.writer open]) return;
        FMDatabase *db = self.writer;
        if (![db beginTransaction]) return;
        BOOL ok = [db executeStatements:@"DROP TABLE IF EXISTS message_search_fts; DROP TABLE IF EXISTS message_search; DELETE FROM message_search_meta WHERE key='index_version'; INSERT INTO message_search_meta(key,value) VALUES('rebuild_generation','1') ON CONFLICT(key) DO UPDATE SET value=CAST(value AS INTEGER)+1; UPDATE message_search_meta SET value=COALESCE((SELECT MAX(mid) FROM messages),'') WHERE key='history_cursor'; INSERT OR IGNORE INTO message_search_pending(mid) SELECT mid FROM messages ORDER BY mid DESC LIMIT 128;"];
        if (ok) ok = [db commit];
        if (!ok) [db rollback];
        if (ok) { self.failed = NO; self.ready = NO; }
        [self requestIndexing];
    });
}

- (void)indexBatch {
    @autoreleasepool {
        if (![self isActive] || ![self openWriter]) return;
        FMDatabase *db = self.writer;
        NSMutableArray *batch = [NSMutableArray new];
        FMResultSet *res = [db executeQuery:@"SELECT p.mid,m.raw,m.cid FROM message_search_pending p LEFT JOIN messages m ON m.mid=p.mid ORDER BY p.rowid LIMIT ?;", @(CHSearchBatchSize)];
        NSUInteger bytes = 0;
        while ([res next]) {
            NSData *raw = [res dataForColumnIndex:1];
            [batch addObject:@{ @"mid": [res stringForColumnIndex:0], @"raw": raw ?: NSNull.null, @"cid": [res dataForColumnIndex:2] ?: NSNull.null, @"pending": @YES }];
            bytes += raw.length;
            if (bytes >= CHSearchBatchBytes) break;
        }
        [res close];
        BOOL pending = batch.count > 0;
        // History runs only after new messages, and yields while a user is searching.
        if (!pending && self.historyIndexingEnabled && CFAbsoluteTimeGetCurrent() - self.lastSearch > 3) {
            NSString *cursor = [db stringForQuery:@"SELECT value FROM message_search_meta WHERE key='history_cursor';"];
            if (cursor.length) {
                res = [db executeQuery:@"SELECT mid,raw,cid FROM messages WHERE mid<=? ORDER BY mid DESC LIMIT ?;", cursor, @(CHSearchBatchSize)];
                while ([res next]) {
                    NSData *raw = [res dataForColumnIndex:1];
                    [batch addObject:@{ @"mid": [res stringForColumnIndex:0], @"raw": raw ?: NSNull.null, @"cid": [res dataForColumnIndex:2] ?: NSNull.null, @"pending": @NO }];
                    bytes += raw.length;
                    if (bytes >= CHSearchBatchBytes) break;
                }
                [res close];
                if (!batch.count) [db executeUpdate:@"UPDATE message_search_meta SET value='' WHERE key='history_cursor';"];
            }
        }
        if (!batch.count) return;
        // Bound each write transaction to one message; parsing/tokenization holds no DB lock.
        for (NSDictionary *item in batch) {
            if (![self isActive]) return;
            NSString *mid = item[@"mid"];
            NSData *raw = item[@"raw"] == NSNull.null ? nil : item[@"raw"];
            NSDictionary *fields = raw ? self.extractor(raw, mid) : nil;
            NSString *title = fields[@"title"] ?: @"";
            NSString *text = fields[@"text"] ?: @"";
            NSString *normalizedTitle = [self.class normalizedText:title];
            NSString *normalizedText = [self.class normalizedText:text];
            NSString *titleTokens = [self.class tokensForText:normalizedTitle];
            NSString *textTokens = [self.class tokensForText:normalizedText];
            NSNumber *oldID = @([db longForQuery:@"SELECT id FROM message_search WHERE mid=?;", mid]);
            NSString *oldTitle = oldID.longLongValue ? [db stringForQuery:@"SELECT normalized_title FROM message_search WHERE id=?;", oldID] : @"";
            NSString *oldText = oldID.longLongValue ? [db stringForQuery:@"SELECT normalized_text FROM message_search WHERE id=?;", oldID] : @"";
            NSString *oldTitleTokens = [self.class tokensForText:oldTitle ?: @""];
            NSString *oldTextTokens = [self.class tokensForText:oldText ?: @""];
            if (![self isActive] || ![db beginTransaction]) return;
            NSData *current = [db dataForQuery:@"SELECT raw FROM messages WHERE mid=?;", mid];
            if ((current || raw) && ![current isEqualToData:raw]) {
                [db rollback];
                continue; // A delete/reinsert occurred during parsing; leave its pending task intact.
            }
            NSNumber *rowID = @([db longForQuery:@"SELECT id FROM message_search WHERE mid=?;", mid]);
            if (rowID.longLongValue != oldID.longLongValue) { [db rollback]; continue; }
            if (rowID.longLongValue == 0) rowID = nil;
            BOOL ok = YES;
            if (rowID) {
                ok = [db executeUpdate:@"INSERT INTO message_search_fts(message_search_fts,rowid,title_tokens,text_tokens) VALUES('delete',?,?,?);", rowID, oldTitleTokens, oldTextTokens];
            }
            if (ok && !current) ok = [db executeUpdate:@"DELETE FROM message_search WHERE mid=?;", mid];
            if (ok && current) {
                ok = [db executeUpdate:@"INSERT INTO message_search(mid,cid,title,text,normalized_title,normalized_text,version) VALUES(?,?,?,?,?,?,?) ON CONFLICT(mid) DO UPDATE SET cid=excluded.cid,title=excluded.title,text=excluded.text,normalized_title=excluded.normalized_title,normalized_text=excluded.normalized_text,version=excluded.version;", mid, item[@"cid"], title, text, normalizedTitle, normalizedText, @(fields ? CHSearchSchemaVersion : -CHSearchSchemaVersion)];
                rowID = ok ? @([db longForQuery:@"SELECT id FROM message_search WHERE mid=?;", mid]) : nil;
                if (ok) ok = [db executeUpdate:@"INSERT INTO message_search_fts(rowid,title_tokens,text_tokens) VALUES(?,?,?);", rowID, titleTokens, textTokens];
            }
            if (ok) ok = [db executeUpdate:@"DELETE FROM message_search_pending WHERE mid=?;", mid];
            if (ok && ![item[@"pending"] boolValue]) {
                // '< mid' avoids reprocessing this boundary, without inventing a predecessor ID.
                NSString *previous = [db stringForQuery:@"SELECT mid FROM messages WHERE mid<? ORDER BY mid DESC LIMIT 1;", mid] ?: @"";
                ok = [db executeUpdate:@"UPDATE message_search_meta SET value=? WHERE key='history_cursor';", previous];
            }
            if (ok) ok = [db commit];
            if (!ok) {
                [db rollback];
                // Lock contention is retryable; an invalid index is disabled until reopened/repaired.
                if (db.lastErrorCode != SQLITE_BUSY && db.lastErrorCode != SQLITE_LOCKED) self.failed = YES;
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self isActive]) [NSNotificationCenter.defaultCenter postNotificationName:@"CHMessageSearchDidUpdate" object:self];
        });
        [self scheduleIndexingAfter:pending ? 0.1 : 1.0];
    }
}

- (void)cancelSearch {
    os_unfair_lock_lock(&_stateLock);
    _generation++;
    if (_readerHandle) sqlite3_interrupt(_readerHandle);
    os_unfair_lock_unlock(&_stateLock);
}

- (void)search:(NSString *)query before:(NSString *)mid limit:(NSUInteger)limit completion:(void (^)(NSArray<NSDictionary *> *, BOOL, BOOL, NSError *))completion {
    [self cancelSearch];
    os_unfair_lock_lock(&_stateLock);
    NSUInteger generation = _generation;
    BOOL closed = _closed;
    os_unfair_lock_unlock(&_stateLock);
    if (closed) return;
    NSString *text = [self.class normalizedText:[query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
    // Prevent arbitrarily large MATCH expressions from unbounded pasted input.
    if (text.length > 256) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(@[], NO, YES, [NSError errorWithDomain:@"ChanifySearch" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Search text is too long"}]); });
        return;
    }
    NSString *match = text.length ? [self.class matchForText:text] : nil;
    dispatch_async(self.worker, ^{ self.lastSearch = CFAbsoluteTimeGetCurrent(); });
    dispatch_async(self.queryQueue, ^{
        os_unfair_lock_lock(&self->_stateLock);
        BOOL valid = !self->_closed && generation == self->_generation;
        os_unfair_lock_unlock(&self->_stateLock);
        if (!valid) return;
        NSMutableArray *items = [NSMutableArray new];
        NSError *error = self.failed || !self.ready ? [NSError errorWithDomain:@"ChanifySearch" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Search index is unavailable"}] : nil;
        BOOL incomplete = YES;
        NSUInteger count = MIN(MAX(limit, 1), 50);
        if (!self.reader) {
            self.reader = [FMDatabase databaseWithURL:self.url];
            if (![self.reader openWithFlags:SQLITE_OPEN_READONLY]) {
                error = self.reader.lastError;
                self.reader = nil;
            }
            self.reader.maxBusyRetryTimeInterval = 0.1;
            os_unfair_lock_lock(&self->_stateLock);
            self->_readerHandle = self.reader.sqliteHandle;
            os_unfair_lock_unlock(&self->_stateLock);
        }
        FMDatabase *db = self.reader;
        // A bounded deadline also covers high-frequency terms and candidate sorting.
        CFAbsoluteTime deadline = CFAbsoluteTimeGetCurrent() + 0.5;
        sqlite3_progress_handler(db.sqliteHandle, 2000, CHSearchDeadline, &deadline);
        if (!error && match) {
            // A bounded chronological prefix avoids sorting millions of common-term hits.
            // LIMIT inside this subquery bounds text inspection; rare terms still use FTS.
            FMResultSet *recent = [db executeQuery:@"SELECT s.mid,s.cid,s.title,s.text,COALESCE(c.name,'') FROM (SELECT * FROM message_search WHERE mid<? ORDER BY mid DESC LIMIT 128) s JOIN messages m ON m.mid=s.mid LEFT JOIN channels c ON c.cid=s.cid WHERE (instr(s.normalized_title,?)>0 OR instr(s.normalized_text,?)>0) ORDER BY s.mid DESC LIMIT ?;", mid ?: @"7FFFFFFFFFFFFFFF", text, text, @(count+1)];
            while ([recent next]) {
                [items addObject:@{ @"mid": [recent stringForColumnIndex:0], @"cid": [recent dataForColumnIndex:1], @"title": [recent stringForColumnIndex:2], @"text": [recent stringForColumnIndex:3], @"channel": [recent stringForColumnIndex:4] }];
            }
            [recent close];
            if (items.count <= count) {
                [items removeAllObjects];
                FMResultSet *res = [db executeQuery:@"SELECT s.mid,s.cid,s.title,s.text,COALESCE(c.name,''),s.version FROM message_search_fts JOIN message_search s ON s.id=message_search_fts.rowid JOIN messages m ON m.mid=s.mid LEFT JOIN channels c ON c.cid=s.cid WHERE message_search_fts MATCH ? AND s.mid<? AND (instr(s.normalized_title,?)>0 OR instr(s.normalized_text,?)>0) ORDER BY s.mid DESC LIMIT ?;", match, mid ?: @"7FFFFFFFFFFFFFFF", text, text, @(count+1)];
                if (!res) error = db.lastError;
                while ([res next]) {
                    [items addObject:@{ @"mid": [res stringForColumnIndex:0], @"cid": [res dataForColumnIndex:1], @"title": [res stringForColumnIndex:2], @"text": [res stringForColumnIndex:3], @"channel": [res stringForColumnIndex:4] }];
                }
                if (db.lastErrorCode != SQLITE_OK && db.lastErrorCode != SQLITE_ROW && db.lastErrorCode != SQLITE_DONE) error = db.lastError;
                [res close];
            }
        }
        sqlite3_progress_handler(db.sqliteHandle, 0, NULL, NULL);
        if (!error) incomplete = [db boolForQuery:@"SELECT EXISTS(SELECT 1 FROM message_search_pending) OR EXISTS(SELECT 1 FROM message_search_meta WHERE key='history_cursor' AND value<>'');"];
        BOOL more = items.count > count;
        if (more) [items removeLastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            os_unfair_lock_lock(&self->_stateLock);
            BOOL current = !self->_closed && generation == self->_generation;
            os_unfair_lock_unlock(&self->_stateLock);
            if (current) completion(error ? @[] : items, more, incomplete, error);
        });
    });
}

static int CHSearchDeadline(void *context) {
    return CFAbsoluteTimeGetCurrent() > *(CFAbsoluteTime *)context;
}

- (void)close {
    os_unfair_lock_lock(&_stateLock);
    if (_closed) { os_unfair_lock_unlock(&_stateLock); return; }
    _closed = YES;
    _generation++;
    if (_readerHandle) sqlite3_interrupt(_readerHandle);
    os_unfair_lock_unlock(&_stateLock);
    if (self.timer) { dispatch_source_cancel(self.timer); self.timer = nil; }
    // Account deletion may remove files immediately after close returns. Drain both
    // connections here; ordinary indexing and query paths never wait on the main thread.
    void (^closeWriter)(void) = ^{ [self.writer close]; self.writer = nil; };
    void (^closeReader)(void) = ^{
        os_unfair_lock_lock(&self->_stateLock);
        self->_readerHandle = NULL;
        os_unfair_lock_unlock(&self->_stateLock);
        [self.reader close]; self.reader = nil;
    };
    if (dispatch_get_specific(&CHSearchWorkerKey) == (__bridge void *)self) closeWriter();
    else dispatch_sync(self.worker, closeWriter);
    if (dispatch_get_specific(&CHSearchReaderKey) == (__bridge void *)self) closeReader();
    else dispatch_sync(self.queryQueue, closeReader);
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (_timer) dispatch_source_cancel(_timer);
    [_writer close];
    [_reader close];
}
@end
