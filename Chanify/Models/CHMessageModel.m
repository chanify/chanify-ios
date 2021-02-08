//
//  CHMessageModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessageModel.h"
#import <UserNotifications/UserNotifications.h>
#import "CHCrpyto.h"
#import "CHTP.pbobjc.h"

@implementation CHMessageModel

+ (nullable instancetype)modelWithData:(nullable NSData *)data mid:(uint64_t)mid {
    if (data.length > 0 && mid > 0) {
        NSError *error = nil;
        CHTPMessage *msg = [CHTPMessage parseFromData:data error:&error];
        if (error != nil) {
            CHLogE("Invalid message format: %s", error.description.cstr);
        } else {
            return [[self.class alloc] initWithID:mid packet:msg];
        }
    }
    return nil;
}

- (instancetype)initWithID:(uint64_t)mid packet:(CHTPMessage *)msg {
    if (self = [super init]) {
        _mid = mid;
        _from = msg.from.base32;
        _channel = msg.channel;
        NSError *error = nil;
        CHTPMsgContent *content = [CHTPMsgContent parseFromData:msg.content error:&error];
        if (error != nil) {
            CHLogE("Invalid message content: %s", error.description.cstr);
        } else {
            switch (content.type) {
                case CHTPMsgType_GPBUnrecognizedEnumeratorValue:
                    _type = CHMessageTypeNone;
                    break;
                case CHTPMsgType_System:
                    _type = CHMessageTypeSystem;
                    break;
                case CHTPMsgType_Text:
                    _type = CHMessageTypeText;
                    _text = content.text;
                    break;
                case CHTPMsgType_Image:
                    _type = CHMessageTypeImage;
                    _text = @"Image";
                    break;
            }
        }
    }
    return self;
}

+ (nullable instancetype)modelWithKey:(nullable NSData *)key data:(nullable NSData *)data raw:(NSData * _Nullable * _Nullable)raw {
    if (key.length >= kCHAesGcmKeyBytes * 2 && data.length > kCHAesGcmNonceBytes + kCHAesGcmTagBytes) {
        uint64_t mid = parseMID(data.bytes);
        if (mid > 0) {
            NSData *payload = [CHCrpyto aesOpenWithKey:[key subdataWithRange:NSMakeRange(0, kCHAesGcmKeyBytes)] data:data auth:[key subdataWithRange:NSMakeRange(kCHAesGcmKeyBytes, kCHAesGcmKeyBytes)]];
            if (payload.length > 0) {
                if (raw != nil) {
                    *raw = payload;
                }
                return [self.class modelWithData:payload mid:mid];
            }
        }
    }
    return nil;
}

+ (nullable NSString *)parsePacket:(NSDictionary *)info mid:(nullable uint64_t *)mid data:(NSData * _Nullable * _Nullable)data {
    NSString *uid = [info valueForKey:@"uid"];
    NSData *payload = [NSData dataFromBase64:[info valueForKey:@"msg"]];
    if (payload.length > kCHAesGcmNonceBytes + kCHAesGcmTagBytes) {
        if (mid != NULL) {
            *mid = parseMID(payload.bytes);
        }
        if (data != nil) {
            *data = payload;
        }
    }
    return uid;
}

- (void)formatNotification:(UNMutableNotificationContent *)content {
    content.body = self.text;
    content.categoryIdentifier = self.channel.sha1.base64;
}

- (NSString *)dateFormat {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.dateStyle = NSDateFormatterShortStyle;
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.mid/1000000000.0]];
}

inline static uint64_t parseMID(const uint8_t *ptr) {
    return CFSwapInt64BigToHost(*(uint64_t *)(ptr + 4));
}


@end
