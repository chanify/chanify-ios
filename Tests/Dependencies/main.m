#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <FMDB/FMDB.h>
#import <JLRoutes/JLRoutes.h>
#import <Masonry/Masonry.h>
#import <Protobuf/GPBProtocolBuffers.h>
#import <Protobuf/GPBProtocolBuffers_RuntimeSupport.h>
#import "Chtp.pbobjc.h"
int main(void) {
    @autoreleasepool {
        FMDatabase *db = [FMDatabase databaseWithPath:@":memory:"];
        NSCAssert([db open], @"SQLite open failed");
        NSCAssert([db executeUpdate:@"CREATE TABLE messages (text TEXT)"], @"Create failed");
        NSCAssert(([db executeUpdate:@"INSERT INTO messages VALUES (?)", @"hello"]), @"Insert failed");
        FMResultSet *rows = [db executeQuery:@"SELECT text FROM messages"];
        NSCAssert([rows next] && [[rows stringForColumnIndex:0] isEqualToString:@"hello"], @"Read failed");
        [rows close]; [db close];
        __block BOOL routed = NO;
        [[JLRoutes routesForScheme:@"chanify"] addRoute:@"/test/:value" handler:^BOOL(NSDictionary *params) {
            routed = [params[@"value"] isEqualToString:@"hello"];
            return routed;
        }];
        NSCAssert([JLRoutes routeURL:[NSURL URLWithString:@"chanify:///test/hello"]] && routed, @"Route failed");
        NSCAssert([NSView instancesRespondToSelector:@selector(mas_makeConstraints:)], @"Masonry category missing");
        GPBStringValue *message = [GPBStringValue message];
        message.value = @"hello";
        NSError *error = nil;
        GPBStringValue *decoded = [GPBStringValue parseFromData:message.data error:&error];
        NSCAssert(error == nil && [decoded.value isEqualToString:@"hello"], @"Protobuf roundtrip failed");
        // Existing channel bytes used by CHTPToken's default channel.
        const uint8_t channelBytes[] = {0x08, 0x01};
        NSData *channelData = [NSData dataWithBytes:channelBytes length:sizeof(channelBytes)];
        CHTPChannel *channel = [CHTPChannel parseFromData:channelData error:&error];
        NSCAssert(error == nil && channel.type == CHTPChanType_Sys, @"Legacy channel failed");
        NSCAssert([channel.data isEqualToData:channelData], @"Channel encoding changed");
        // Text content plus an unknown field (#127) must survive read/write.
        const uint8_t contentBytes[] = {0x08, 0x01, 0x12, 0x05, 'h', 'e', 'l', 'l', 'o',
                                        0xf8, 0x07, 0x2a};
        NSData *contentData = [NSData dataWithBytes:contentBytes length:sizeof(contentBytes)];
        CHTPMsgContent *content = [CHTPMsgContent parseFromData:contentData error:&error];
        NSCAssert(error == nil && [content.text isEqualToString:@"hello"], @"Legacy text failed");
        NSCAssert([content.data isEqualToData:contentData], @"Unknown field lost");
        // Negative enum values use a ten-byte varint in existing notifications.
        const uint8_t passiveBytes[] = {0x40, 0xff, 0xff, 0xff, 0xff, 0xff,
                                        0xff, 0xff, 0xff, 0xff, 0x01};
        NSData *passiveData = [NSData dataWithBytes:passiveBytes length:sizeof(passiveBytes)];
        CHTPMessage *passive = [CHTPMessage parseFromData:passiveData error:&error];
        NSCAssert(error == nil && passive.interruptionLevel == CHTPInterruptionLevel_IlPassive,
                  @"Negative interruption enum failed");
        NSCAssert([passive.data isEqualToData:passiveData], @"Negative enum encoding changed");
        // Exercise nested and repeated messages shared with the Watch app.
        CHTPWatchConfig *config = [CHTPWatchConfig message];
        CHTPNode *node = [CHTPNode message];
        node.nid = @"test-node";
        [config.nodesArray addObject:node];
        CHTPWatchConfig *watch = [CHTPWatchConfig parseFromData:config.data error:&error];
        NSCAssert(error == nil && watch.nodesArray.count == 1 &&
                  [watch.nodesArray.firstObject.nid isEqualToString:@"test-node"],
                  @"Watch configuration failed");
        const uint8_t malformedBytes[] = {0xff};
        NSError *malformedError = nil;
        GPBStringValue *malformed = [GPBStringValue parseFromData:[NSData dataWithBytes:malformedBytes length:sizeof(malformedBytes)] error:&malformedError];
        NSCAssert(malformed == nil && malformedError != nil, @"Malformed protobuf must return an error");
        puts("PASS: FMDB SQLite, JLRoutes, Masonry category, Protobuf roundtrip and CHTP wire compatibility");
    }
    return 0;
}
