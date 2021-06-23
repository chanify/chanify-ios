//
//  CHWidget.m
//  iOS
//
//  Created by WizJin on 2021/6/17.
//

#import "CHWidget.h"
#import <FMDB.h>
#import <sqlite3.h>
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHLogic+iOS.h"

#define kCHWidgetDBVersion  1
#define kCHWSInitSql        \
    "CREATE TABLE IF NOT EXISTS `channels`(`uid` TEXT,`cid` TEXT,`name` TEXT,`icon` TEXT,PRIMARY KEY(`uid`,`cid`));" \

@interface CHWidgetKit
+ (void)reloadAllTimelines;
@end

@interface CHWidget () {
@private
    BOOL    isReloadNeeded;
}

@property (nonatomic, nullable, strong) NSString *uid;
@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;

@end

@implementation CHWidget

+ (instancetype)shared {
    static CHWidget *widget = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        widget = [CHWidget new];
    });
    return widget;
}

- (instancetype)init {
    if (self = [super init]) {
        isReloadNeeded = YES;
        _uid = nil;
        NSURL *url = [NSFileManager.defaultManager URLForGroupId:@kCHAppWidgetGroupName path:@kCHDBWidgetName];
        _dbQueue = [FMDatabaseQueue databaseQueueWithURL:url flags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|kCHDBFileProtectionFlags];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if ([db executeStatements:@kCHWSInitSql]) {
                NSURL *dbURL = db.databaseURL;
                dbURL.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
                CHLogI("Open widget shared database: %s", dbURL.path.cstr);
            }
        }];
    }
    return self;
}

- (void)reloadDB:(nullable NSString *)uid {
    if (![_uid isEqualToString:uid]) {
        _uid = uid;
        isReloadNeeded = YES;
        if (_uid.length > 0) {
            [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                int n = [db intForQuery:@"SELECT COUNT(*) FROM `channels` WHERE `uid`=?;", uid];
                if (n > 0 && db.userVersion == 0) {
                    db.userVersion = kCHWidgetDBVersion;
                    n = 0;
                }
                CHUserDataSource *userDataSource = CHLogic.shared.userDataSource;
                if (n <= 0) {
                    NSArray<CHChannelModel *> *channels = userDataSource.loadChannels;
                    for (CHChannelModel *model in channels) {
                        if (!upsertChannel(db, uid, model)) {
                            *rollback = YES;
                            break;
                        }
                    }
                }
            }];
        }
    }
}

- (void)reloadIfNeeded {
    if (isReloadNeeded) {
        isReloadNeeded = NO;
        [self.dbQueue close];
        [CHWidgetKit reloadAllTimelines];
    }
}

- (void)upsertChannel:(CHChannelModel *)model {
    if (self.uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if (upsertChannel(db, self.uid, model)) {
                isReloadNeeded = YES;
            }
        }];
    }
}

- (void)deleteChannel:(nullable NSString *)cid {
    if (self.uid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            if ([db executeUpdate:@"DELETE FROM `channels` WHERE `uid`=? AND `cid`=? LIMIT 1;", self.uid, cid]) {
                isReloadNeeded = YES;
            }
        }];
    }
}

#pragma mark - Private Methods
static inline BOOL upsertChannel(FMDatabase *db, NSString *uid, CHChannelModel *model) {
    NSString *name = (model.type == CHChanTypeSys ? model.code : model.title);
    return [db executeUpdate:@"INSERT INTO `channels`(`uid`,`cid`,`name`,`icon`) VALUES(?,?,?,?) ON CONFLICT(`uid`,`cid`) DO UPDATE SET `name`=excluded.`name`,`icon`=excluded.`icon`;", uid, model.cid, name, model.icon];
}


@end
