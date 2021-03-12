//
//  CHToken.m
//  Chanify
//
//  Created by WizJin on 2021/3/12.
//

#import "CHToken.h"
#import "CHLogic.h"
#import "CHDevice.h"
#import "CHCrpyto.h"
#import "CHNodeModel.h"
#import "CHNSDataSource.h"
#import "CHTP.pbobjc.h"

@interface CHToken ()

@property (nonatomic, readonly, strong) CHTPToken *token;

@end

@implementation CHToken

+ (instancetype)tokenWithTimeInterval:(NSTimeInterval)timeInterval {
    return [[self.class alloc] initWithTimeInterval:timeInterval];
}

+ (instancetype)defaultToken {
    CHToken *token = [CHToken tokenWithTimeInterval:90*24*60*60];
    token.channel = [NSData dataFromHex:@"0801"];
    return token;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval {
    NSCalendar *calender = NSCalendar.currentCalendar;
    NSDate *date = [calender dateBySettingHour:0 minute:0 second:0 ofDate:NSDate.now options:NSCalendarMatchFirst];
    date = [date dateByAddingTimeInterval:NSCalendar.currentCalendar.timeZone.secondsFromGMT + timeInterval];
    if (self = [super init]) {
        _token = [CHTPToken new];
        self.token.expires = date.timeIntervalSince1970;
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
    if ([node.nid isEqualToString:@"sys"]) {
        self.token.nodeId = nil;
    } else {
        self.token.nodeId = node.nid;
    }
}

- (NSString *)stringValue {
    NSData *token = self.token.data;
    NSData *key = [CHLogic.shared.nsDataSource keyForUID:self.token.userId];
    NSData *sign = [CHCrpyto hmacSha256:token secret:[key subdataWithRange:NSMakeRange(0, 256/8)]];
    return [NSString stringWithFormat:@"%@.%@", token.base64, sign.base64];
}


@end
