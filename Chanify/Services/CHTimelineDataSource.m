//
//  CHTimelineDataSource.m
//  iOS
//
//  Created by WizJin on 2021/8/20.
//

#import "CHTimelineDataSource.h"
#import <FMDB.h>
#import <sqlite3.h>

#define kCHNSInitSql    \
    "CREATE TABLE IF NOT EXISTS `tspts`(`uid` TEXT,`code` TEXT,`from` TEXT,`point` TIMESTAMP,`content` BLOB, PRIMARY KEY(`uid`,`code`,`from`,`point`));"  \


@interface CHTimelineDataSource ()

@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;

@end

@implementation CHTimelineDataSource

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
                CHLogI("Open timeline database: %s", dbURL.path.cstr);
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

- (BOOL)upsertUid:(NSString *)uid from:(NSString *)from model:(nullable CHTimelineModel *)model {
    __block BOOL res = YES;
    if (model != nil) {
        res = NO;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:@"INSERT OR IGNORE INTO `tspts`(`uid`,`code`,`from`,`point`,`content`) VALUES(?,?,?,?,?);", uid, model.code, from, model.timestamp, model.data];
        }];
    }
    return res;
}


@end
