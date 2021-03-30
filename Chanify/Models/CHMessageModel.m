//
//  CHMessageModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessageModel.h"
#import <UserNotifications/UserNotifications.h>
#import "CHNSDataSource.h"
#import "CHUserDataSource.h"
#import "CHCrpyto.h"
#import "CHTP.pbobjc.h"

@implementation CHMessageModel

+ (nullable instancetype)modelWithData:(nullable NSData *)data mid:(NSString *)mid {
    if (data.length > 0 && mid.length > 0) {
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

+ (nullable instancetype)modelWithKS:(id<CHKeyStorage>)ks uid:(NSString *)uid mid:(NSString *)mid data:(nullable NSData *)data raw:(NSData * _Nullable * _Nullable)raw {
    if (mid.length > 0) {
        NSString *keyID = uid;
        NSString *src = getSrcFromMID(mid);
        if (src.length > 0) keyID = [keyID stringByAppendingFormat:@".%@", src];

        NSData *key = [ks keyForUID:keyID];
        if (key.length >= kCHAesGcmKeyBytes * 2 && data.length > kCHAesGcmNonceBytes + kCHAesGcmTagBytes) {
            NSData *payload = [CHCrpyto aesOpenWithKey:[key subdataWithRange:NSMakeRange(0, kCHAesGcmKeyBytes)] data:data auth:[key subdataWithRange:NSMakeRange(kCHAesGcmKeyBytes, kCHAesGcmKeyBytes)]];
            if (payload.length > 0) {
                NSError *error = nil;
                CHTPMessage *msg = [CHTPMessage parseFromData:payload error:&error];
                if (error == nil && msg != nil) {
                    if (msg.ciphertext.length > kCHAesGcmNonceBytes + kCHAesGcmTagBytes) {
                        key = [ks keyForUID:[NSString stringWithFormat:@"%@.%@", uid, msg.from.base32]];
                        if (key.length >= kCHAesGcmKeyBytes * 2) {
                            NSData *outdata = [CHCrpyto aesOpenWithKey:[key subdataWithRange:NSMakeRange(0, kCHAesGcmKeyBytes)] data:msg.ciphertext auth:[key subdataWithRange:NSMakeRange(kCHAesGcmKeyBytes, kCHAesGcmKeyBytes)]];
                            if (outdata.length <= 0) {
                                CHLogE("Invalid message key");
                                return nil;
                            } else {
                                msg.content = outdata;
                                msg.ciphertext = nil;
                                payload = msg.data;
                            }
                        }
                    }
                    if (raw != nil) {
                        *raw = payload;
                    }
                    return [self.class modelWithData:payload mid:mid];
                }
            }
        }
    }
    return nil;
}

+ (nullable NSString *)parsePacket:(NSDictionary *)info mid:(NSString * _Nullable * _Nullable)mid data:(NSData * _Nullable * _Nullable)data {
    NSString *uid = [info valueForKey:@"uid"];
    NSString *src = [info valueForKey:@"src"];
    NSData *payload = [NSData dataFromBase64:[info valueForKey:@"msg"]];
    if (payload.length > kCHAesGcmNonceBytes + kCHAesGcmTagBytes) {
        if (mid != nil) {
            *mid = parseMID(payload.bytes, src);
        }
        if (data != nil) {
            *data = payload;
        }
    }
    return uid;
}

- (instancetype)initWithID:(NSString *)mid packet:(CHTPMessage *)msg {
    if (self = [super init]) {
        _mid = mid;
        _from = msg.from.base32;
        _channel = msg.channel;

        CHTPSound *sound = msg.sound;
        if (sound != nil && sound.type == CHTPSoundType_NormalSound) {
            _sound = sound.name;
        }
        
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
                    if (content.title.length > 0) {
                        _title = content.title;
                    }
                    _text = [content.text stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
                    break;
                case CHTPMsgType_Image:
                    _type = CHMessageTypeImage;
                    _text = @"Image".localized;
                    _file = content.file;
                    if (content.hasThumbnail) {
                        CHTPThumbnail *thumbnail = content.thumbnail;
                        if (thumbnail.type == 0) {
                            NSData *preview = thumbnail.data_p;
                            if (preview.length <= 0) preview = nil;
                            _thumbnail = [CHThumbnailModel thumbnailWithWidth:thumbnail.width height:thumbnail.height preview:preview];
                        }
                    }
                    break;
                case CHTPMsgType_Video:
                    _type = CHMessageTypeVideo;
                    _text = @"Video".localized;
                    break;
                case CHTPMsgType_Audio:
                    _type = CHMessageTypeAudio;
                    _text = @"Audio".localized;
                    break;
            }
        }
    }
    return self;
}

- (void)formatNotification:(UNMutableNotificationContent *)content {
    content.categoryIdentifier = self.channel.sha1.base64;
    if (self.text.length > 0) {
        content.body = self.text;
    }
    if (self.title.length > 0) {
        content.title = self.title;
    }
    if (self.sound.length > 0) {
        content.sound = [UNNotificationSound defaultSound];
    }
}

- (nullable NSString *)fileURL {
    if (self.file.length > 0) {
        if ([self.file characterAtIndex:0] == '/' && self.from.length > 0) {
            return [NSString stringWithFormat:@"!%@:%@", self.from, self.file];
        }
        return self.file;
    }
    return nil;
}

- (BOOL)isEqual:(CHMessageModel *)rhs {
    return [self.mid isEqualToString:rhs.mid];
}

- (NSUInteger)hash {
    return self.mid.hash;
}

inline static NSString *getSrcFromMID(NSString *mid) {
    NSString *res = nil;
    if (mid.length > 0) {
        NSArray *items = [mid componentsSeparatedByString:@"."];
        if (items.count > 1) {
            res = [items objectAtIndex:1];
        }
    }
    return res;
}

inline static NSString *parseMID(const uint8_t *ptr, NSString *str) {
    uint64_t mid = CFSwapInt64BigToHost(*(uint64_t *)(ptr + 4));
    if (mid <= 0) {
        return @"";
    }
    if (str.length <= 0) {
        return [NSString stringWithFormat:@"%016llX", mid];
    }
    return [NSString stringWithFormat:@"%016llX.%@", mid, str];
}


@end
