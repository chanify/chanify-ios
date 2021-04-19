//
//  CHWatchLogic.m
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

#import "CHWatchLogic.h"

@implementation CHWatchLogic

+ (instancetype)shared {
    static CHWatchLogic *logic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logic = [CHWatchLogic new];
    });
    return logic;
}


@end
