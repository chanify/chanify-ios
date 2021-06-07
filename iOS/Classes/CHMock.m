//
//  CHMock.m
//  Chanify
//
//  Created by WizJin on 2021/2/9.
//

#import "CHMock.h"
#if TARGET_OS_SIMULATOR
#import "CHNSDataSource.h"
#import "CHUserDataSource.h"
#import "CHLogic+iOS.h"
#import "CHCrpyto.h"
#import "CHTP.pbobjc.h"

NSDictionary *try_mock_notification(NSDictionary* info) {
    CHUserModel *me = CHLogic.shared.me;
    NSString *uid = me.uid;
    NSString *chn = [info valueForKeyPath:@"aps.alert.channel"];
    uint64_t mid = get_utc_time64();
    CHTPMsgContent *content = [CHTPMsgContent new];
    if ([[info valueForKeyPath:@"aps.alert.image"] length] > 0) {
        content.type = CHTPMsgType_Image;
        content.file = [info valueForKeyPath:@"aps.alert.image"];
    } else if ([[info valueForKeyPath:@"aps.alert.audio"] length] > 0) {
        content.type = CHTPMsgType_Audio;
        content.file = [info valueForKeyPath:@"aps.alert.audio"];
    } else if ([[info valueForKeyPath:@"aps.alert.file"] length] > 0) {
        content.type = CHTPMsgType_File;
        content.file = [info valueForKeyPath:@"aps.alert.file"];
        content.filename = [info valueForKeyPath:@"aps.alert.filename"];
    } else if ([[info valueForKeyPath:@"aps.alert.link"] length] > 0) {
        content.type = CHTPMsgType_Link;
        content.link = [info valueForKeyPath:@"aps.alert.link"];
    } else {
        content.type = CHTPMsgType_Text;
        content.text = [info valueForKeyPath:@"aps.alert.text"];
        content.title = [info valueForKeyPath:@"aps.alert.title"];
    }
    CHTPMessage *msg = [CHTPMessage new];
    if (chn.length <= 0) {
        msg.channel = [NSData dataFromHex:@kCHDefChanCode];
    } else {
        CHTPChannel *chan = [CHTPChannel new];
        chan.type = CHTPChanType_User;
        chan.name = chn;
        msg.channel = chan.data;
    }
    msg.content = content.data;
    NSData *payload = msg.data;
    NSMutableData *nonce = [NSMutableData dataWithLength:kCHAesGcmNonceBytes];
    uint8_t *ptr = (uint8_t *)nonce.mutableBytes;
    ptr[0] = 0x01;
    ptr[1] = 0x01;
    ptr[2] = 0x00;
    ptr[2] = 0x08;
    *(uint64_t *)(ptr + 4) = CFSwapInt64BigToHost(mid);
    CHNSDataSource *nsDS = CHLogic.shared.nsDataSource;
    NSData *key = [nsDS keyForUID:uid];
    NSData *data = [CHCrpyto aesSealWithKey:[key subdataWithRange:NSMakeRange(0, kCHAesGcmKeyBytes)] data:payload nonce:nonce auth:[key subdataWithRange:NSMakeRange(kCHAesGcmKeyBytes, key.length - kCHAesGcmKeyBytes)]];
    [nsDS pushMessage:data mid:[NSString stringWithFormat:@"%016llX", mid] uid:uid blocked:nil];
    return @{
        @"uid": uid,
        @"msg": data.base64,
    };
}

#endif
