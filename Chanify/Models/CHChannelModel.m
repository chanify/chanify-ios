//
//  CHChannelModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelModel.h"
#include "CHTP.pbobjc.h"

@implementation CHChannelModel

+ (instancetype)modelWithCID:(nullable NSString *)cid name:(NSString *)name icon:(NSString *)icon {
    CHChannelModel *model = [self.class new];
    model->_cid = (cid != nil ? cid : @"");
    model->_name = name;
    model->_icon = icon;

    NSError *error = nil;
    CHTPChannel *chan = [CHTPChannel parseFromData:[NSData dataFromBase64:cid] error:&error];
    if (error == nil) {
        if (chan.type == CHTPChanType_Sys) {
            switch (chan.code) {
                case CHTPChanCode_GPBUnrecognizedEnumeratorValue:
                    break;
                case CHTPChanCode_Uncategorized:
                    if (name.length <= 0) {
                        model->_name = @"sys.none".localized;
                    }
                    if (icon.length <= 0) {
                        model->_icon = @"sys://tray.2.fill";
                    }
                    break;
                case CHTPChanCode_Device:
                    if (name.length <= 0) {
                        model->_name = @"sys.device".localized;
                    }
                    if (icon.length <= 0) {
                        model->_icon = @"sys://iphone";
                    }
                    break;
            }
        }
    }
    return model;
}

- (BOOL)isEqual:(CHChannelModel *)rhs {
    return [self.cid isEqualToString:rhs.cid];
}


@end
