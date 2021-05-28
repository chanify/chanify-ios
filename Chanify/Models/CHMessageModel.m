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
        if (src.length > 0) {
            keyID = [keyID stringByAppendingFormat:@".%@", src];
        }
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
        _channel = msg.channel ?: [NSData dataFromHex:@kCHDefChanCode];

        CHTPSound *sound = msg.sound;
        if (sound != nil && sound.type == CHTPSoundType_NormalSound) {
            _sound = sound.name;
        }

        NSError *error = nil;
        CHTPMsgContent *content = [CHTPMsgContent parseFromData:msg.content error:&error];
        if (error != nil) {
            CHLogE("Invalid message content: %s", error.description.cstr);
        } else {
            _flags = (CHMessageFlags)content.flags;
            _fileSize = content.size;
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
                    if (content.copytext.length > 0) {
                        _copytext = content.copytext;
                    }
                    _text = [content.text stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
                    break;
                case CHTPMsgType_Image:
                    _type = CHMessageTypeImage;
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
                    break;
                case CHTPMsgType_Audio:
                    _type = CHMessageTypeAudio;
                    _file = content.file;
                    _duration = content.duration;
                    break;
                case CHTPMsgType_Link:
                    _type = CHMessageTypeLink;
                    _link = [NSURL URLWithString:content.link];
                    break;
                case CHTPMsgType_File:
                    _type = CHMessageTypeFile;
                    _file = content.file;
                    if (content.filename.length > 0) {
                        _filename = content.filename;
                    }
                    if (content.title.length > 0) {
                        _title = content.title;
                    }
                    if (content.text.length > 0) {
                        _text = content.text;
                    }
                    break;
                case CHTPMsgType_Action:
                    _type = CHMessageTypeAction;
                    if (content.title.length > 0) {
                        _title = content.title;
                    }
                    _text = [content.text stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
                    if (content.actionsArray_Count > 0) {
                        NSMutableArray<CHActionItemModel *> *items = [NSMutableArray arrayWithCapacity:content.actionsArray_Count];
                        for (CHTPActionItem *item in content.actionsArray) {
                            if (item.type == CHTPActType_ActURL) {
                                NSURL *link = [NSURL URLWithString:item.link];
                                if (link != nil) {
                                    [items addObject:[CHActionItemModel actionItemWithName:item.name link:link]];
                                }
                            }
                        }
                        if (items.count > 0) {
                            _actions = items;
                        }
                    }
                    break;
                case CHTPMsgType_Timeline:
                    _type = CHMessageTypeTimeline;
                    break;
            }
        }
    }
    return self;
}

- (void)formatNotification:(UNMutableNotificationContent *)content {
    content.categoryIdentifier = @"general";
    switch (self.type) {
        default: break;
        case CHMessageTypeText:
        {
            NSString *copy = self.copyTextString;
            if (copy.length > 0) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:content.userInfo];
                [userInfo setValue:copy forKey:@"copy"];
                if (self.flags & CHMessageFlagAutoCopy) {
                    [userInfo setValue:@(TRUE) forKey:@"autocopy"];
                }
                content.userInfo = userInfo;
                content.categoryIdentifier = @"text";
            }
        }
            break;
        case CHMessageTypeLink:
            if (self.link != nil) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:content.userInfo];
                [userInfo setValue:self.link.absoluteString forKey:@"link"];
                content.userInfo = userInfo;
                content.categoryIdentifier = @"link";
            }
            break;
        case CHMessageTypeAction:
            if (self.actions.count > 0) {
                NSMutableArray *actions = [NSMutableArray arrayWithCapacity:self.actions.count];
                for (CHActionItemModel *item in self.actions) {
                    [actions addObject:item.dictionary];
                }
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:content.userInfo];
                [userInfo setValue:actions forKey:@"actions"];
                content.userInfo = userInfo;
            }
            break;
    }
    content.threadIdentifier = self.channel.sha1.base64;
    content.body = self.summaryBodyText;
    if (self.title.length > 0) {
        content.title = self.title;
    }
    if (self.sound.length > 0) {
        content.sound = [UNNotificationSound defaultSound];
    }
}

- (NSString *)summaryText {
    return (self.title.length > 0 ? self.title : self.summaryBodyText);
}

- (NSString *)summaryBodyText {
    NSString *txt = self.text;
    if (txt.length <= 0) {
        switch (self.type) {
            case CHMessageTypeImage:
                txt = @"ImageMsg".localized;
                break;
            case CHMessageTypeVideo:
                txt = @"VideoMsg".localized;
                break;
            case CHMessageTypeAudio:
                txt = @"AudioMsg".localized;
                break;
            case CHMessageTypeLink:
                txt = @"LinkMsg".localized;
                if (self.link != nil) {
                    txt = [txt stringByAppendingFormat:@" %@", self.link.absoluteString];
                }
                break;
            case CHMessageTypeFile:
                txt = @"FileMsg".localized;
                if (self.title.length > 0) {
                    txt = [txt stringByAppendingFormat:@" %@", self.title];
                } else if (self.text.length > 0) {
                    txt = [txt stringByAppendingFormat:@" %@", self.text];
                } else if (self.filename.length > 0) {
                    txt = [txt stringByAppendingFormat:@" %@", self.filename];
                }
                break;
            default:
                txt = @"NewMsg".localized;
                break;
        }
    }
    return txt;
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

- (nullable NSString *)copyTextString {
    NSString *copy = self.copytext;
    if (copy.length <= 0) copy = self.text;
    return copy;
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
