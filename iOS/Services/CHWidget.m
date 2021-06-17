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

#define kCHWSInitSql    \
    "CREATE TABLE IF NOT EXISTS `channels`(`uid` TEXT,`cid` TEXT,`name` TEXT,`icon` TEXT,PRIMARY KEY(`uid`,`cid`));" \
    "CREATE TABLE IF NOT EXISTS `nodes`(`uid` TEXT,`nid` TEXT,`name` TEXT,`icon` TEXT,PRIMARY KEY(`uid`,`nid`));" \

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
        if (_uid.length > 0) {
            [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                int n = [db intForQuery:@"SELECT COUNT(*) FROM `channels` WHERE `uid`=?;", uid];
                if (n <= 0) {
                    NSArray<CHChannelModel *> *channels = [CHLogic.shared.userDataSource loadChannels];
                    for (CHChannelModel *channel in channels) {
                        NSString *name = (channel.type == CHChanTypeSys ? channel.code : channel.title);
                        BOOL res = [db executeUpdate:@"INSERT INTO `channels`(`uid`,`cid`,`name`,`icon`) VALUES(?,?,?,?) ON CONFLICT(`uid`,`cid`) DO UPDATE SET `name`=excluded.`name`,`icon`=excluded.`icon`;", uid, channel.cid, name, channel.icon];
                        if (!res) {
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


@end
