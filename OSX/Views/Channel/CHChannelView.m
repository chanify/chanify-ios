//
//  CHChannelView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHChannelView.h"

@implementation CHChannelView

- (instancetype)initWithCID:(NSString *)cid {
    if (self = [super initWithFrame:NSZeroRect]) {
        _cid = cid;
    }
    return self;
}

- (void)dealloc {
    
}


@end
