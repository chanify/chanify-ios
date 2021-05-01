//
//  CHToken.m
//  Chanify
//
//  Created by WizJin on 2021/3/12.
//

#import "CHToken.h"
#import "CHDevice.h"
#import "CHCrpyto.h"
#import "CHNodeModel.h"
#import "CHLogic+iOS.h"
#import "CHNSDataSource.h"
#import "CHTP.pbobjc.h"

@interface CHToken ()

@property (nonatomic, readonly, strong) CHTPToken *token;

@end

@implementation CHToken

+ (instancetype)tokenWithTimeInterval:(NSTimeInterval)timeInterval {
    NSCalendar *calender = NSCalendar.currentCalendar;
    NSDate *date = [calender dateBySettingHour:0 minute:0 second:0 ofDate:NSDate.now options:NSCalendarMatchFirst];
    date = [date dateByAddingTimeInterval:NSCalendar.currentCalendar.timeZone.secondsFromGMT + timeInterval];
    return [[self.class alloc] initWithUTC:date.timeIntervalSince1970];
}

+ (instancetype)tokenWithTimeOffset:(NSTimeInterval)timeOffset {
    return [[self.class alloc] initWithUTC:NSDate.now.timeIntervalSince1970 +  timeOffset];
}

+ (instancetype)defaultToken {
    CHToken *token = [CHToken tokenWithTimeInterval:90*24*60*60];
    token.channel = [NSData dataFromHex:@"0801"];
    return token;
}

- (instancetype)initWithUTC:(uint64_t)utc {
    if (self = [super init]) {
        _token = [CHTPToken new];
        self.token.expires = utc;
        self.token.userId = CHLogic.shared.me.uid;
    }
    return self;
}

- (void)setChannel:(NSData *)channel {
    self.token.channel = channel;
    CHTPChannel *chan = [CHTPChannel parseFromData:channel error:nil];
    if (chan.type == CHTPChanType_Sys && chan.code == CHTPChanCode_Device) {
        self.token.deviceId = CHDevice.shared.uuid;
    }
}

- (void)setNode:(CHNodeModel *)node {
    if (node.isSystem) {
        self.token.nodeId = nil;
    } else {
        self.token.nodeId = node.nid;
    }
}

- (void)setDataHash:(nullable NSData *)data {
    self.token.dataHash = data.sha1;
}

- (NSString *)formatString:(nullable NSString *)source direct:(BOOL)direct {
    if (source.length <= 0) source = @"sys";
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    NSData *token = self.token.data;
    [items addObject:token.base64];
    if (![source isEqualToString:@"sys"] && direct) {
        [items addObject:@""];
    } else {
        NSData *key = [CHLogic.shared.nsDataSource keyForUID:self.token.userId];
        NSData *sign = [CHCrpyto hmacSha256:token secret:[key subdataWithRange:NSMakeRange(0, 256/8)]];
        [items addObject:sign.base64];
    }
    if (![source isEqualToString:@"sys"]) {
        NSData *key = [CHLogic.shared.nsDataSource keyForUID:[self.token.userId stringByAppendingFormat:@".%@", source]];
        NSData *sign = [CHCrpyto hmacSha256:token secret:[key subdataWithRange:NSMakeRange(0, 256/8)]];
        [items addObject:sign.base64];
    }
    return [items componentsJoinedByString:@"."];
}


@end