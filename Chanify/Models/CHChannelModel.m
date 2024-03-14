//
//  CHChannelModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelModel.h"
#import "CHTP.pbobjc.h"

@implementation CHChannelModel

+ (nullable instancetype)modelWithCID:(nullable NSString *)cid name:(nullable NSString *)name icon:(nullable NSString *)icon {
    CHChannelModel *model = nil;
    NSError *error = nil;
    CHTPChannel *chan = [CHTPChannel parseFromData:[NSData dataFromBase64:cid] error:&error];
    if (error == nil) {
        if (chan.type == CHTPChanType_User) {
            model = [self.class new];
            model->_cid = cid;
            model->_code = chan.name;
            model->_name = name;
            model->_icon = icon;
            model->_type = CHChanTypeUser;
        } else if (chan.type == CHTPChanType_Sys) {
            model = [self.class new];
            model->_cid = cid;
            model->_name = name;
            model->_type = CHChanTypeSys;
            switch (chan.code) {
                case CHTPChanCode_GPBUnrecognizedEnumeratorValue:break;
                case CHTPChanCode_Uncategorized:
                    model->_code = @"sys.none";
                    model->_icon = @"sys://tray.2.fill";
                    break;
                case CHTPChanCode_Device:
                    model->_code = @"sys.device";
                    model->_icon = @"sys://iphone";
                    break;
                case CHTPChanCode_TimeSets:
                    model->_code = @"sys.timesets";
                    model->_icon = @"sys://waveform.path.ecg";
                    break;
            }
        }
    }
    return model;
}

+ (nullable instancetype)modelWithCode:(NSString *)code name:(nullable NSString *)name icon:(nullable NSString *)icon {
    CHChannelModel *model = nil;
    if (code.length > 0) {
        CHTPChannel *chan = [CHTPChannel new];
        chan.type = CHTPChanType_User;
        chan.name = code;

        model = [self.class new];
        model->_cid = chan.data.base64Code;
        model->_code = code;
        model->_name = name;
        model->_icon = icon;
    }
    return model;
}

- (NSComparisonResult)channelCompare:(CHChannelModel *)rhs {
    if (self.mid == nil) {
        if (rhs.mid == nil) {
            return NSOrderedSame;
        }
        return NSOrderedDescending;
    }
    switch ([self.mid compare:rhs.mid]) {
        case NSOrderedSame:
            return [self.cid compare:rhs.cid];
        case NSOrderedAscending:
            return NSOrderedDescending;
        case NSOrderedDescending:
            return NSOrderedAscending;
    }
}

- (NSString *)title {
    return (self.name.length > 0 ? self.name : self.code.localized);
}

- (BOOL)isEqual:(CHChannelModel *)rhs {
    return [self.cid isEqualToString:rhs.cid];
}

- (NSUInteger)hash {
    return self.cid.hash;
}


@end
