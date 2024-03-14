//
//  CHWidgetManager.m
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/17.
//

#import "CHWidgetManager.h"
#import <FMDB/FMDB.h>
#import <sqlite3.h>
#import "CHUserModel.h"

@interface CHWidgetManager ()

@property (nonatomic, nullable, strong) NSString *uid;
@property (nonatomic, readonly, strong) FMDatabaseQueue *dbQueue;

@end

@implementation CHWidgetManager

+ (instancetype)shared {
    static CHWidgetManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CHWidgetManager new];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _uid = readUID();
        NSURL *url = [NSFileManager.defaultManager URLForGroupId:@kCHAppWidgetGroupName path:@kCHDBWidgetName];
        _dbQueue = [FMDatabaseQueue databaseQueueWithURL:url flags:SQLITE_OPEN_READONLY|kCHDBFileProtectionFlags];
    }
    return self;
}

- (BOOL)isLogin {
    NSString *uid = readUID();
    if (![_uid isEqualToString:uid]) {
        _uid = uid;
    }
    return (self.uid.length > 0);
}

- (NSString *)channelName:(NSString *)cid {
    __block NSString *name = nil;
    if (self.uid.length > 0 && cid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            name = [db stringForQuery:@"SELECT `name` FROM `channels` WHERE `uid`=? AND `cid`=? LIMIT 1;", self.uid, cid];
            if (name.length > 0) {
                name = name.localized;
            }
        }];
    }
    return name ?: @"";
}

- (NSString *)channelIcon:(NSString *)cid {
    __block NSString *icon = nil;
    if (self.uid.length > 0 && cid.length > 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            icon = [db stringForQuery:@"SELECT `icon` FROM `channels` WHERE `uid`=? AND `cid`=? LIMIT 1;", self.uid, cid];
        }];
    }
    return icon ?: @"";
}

#pragma mark - Private Methods
static inline NSString *readUID(void) {
    return [[CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]] uid];
}


@end
