//
//  CHChannelModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelModel.h"
#include "CHTP.pbobjc.h"

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
                    model->_code = @"sys.none".localized;
                    model->_icon = @"sys://tray.2.fill";
                    break;
                case CHTPChanCode_Device:
                    model->_code = @"sys.device".localized;
                    model->_icon = @"sys://iphone";
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
        model->_cid = chan.data.base64;
        model->_code = code;
        model->_name = name;
        model->_icon = icon;
    }
    return model;
}

- (NSComparisonResult)messageCompare:(CHChannelModel *)rhs {
    if (self.mid == rhs.mid) {
        return [self.cid compare:rhs.cid];
    }
    return (self.mid > rhs.mid ? NSOrderedAscending : NSOrderedDescending);
}

- (NSString *)title {
    return (self.name.length > 0 ? self.name : self.code);
}

- (BOOL)isEqual:(CHChannelModel *)rhs {
    return [self.cid isEqualToString:rhs.cid];
}

- (NSUInteger)hash {
    return self.cid.hash;
}


@end
