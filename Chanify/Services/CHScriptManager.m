//
//  CHScriptManager.m
//  Chanify
//
//  Created by WizJin on 2022/4/1.
//

#import "CHScriptManager.h"
#import "CHUserDataSource.h"

@interface CHScriptManager ()

@property (nonatomic, readonly, weak) CHUserDataSource *ds;

@end

@implementation CHScriptManager

+ (instancetype)scriptManagerWithUID:(NSString *)uid datasource:(CHUserDataSource *)ds {
    return [[self.class alloc] initWithUID:uid datasource:ds];
}

- (instancetype)initWithUID:(NSString *)uid datasource:(CHUserDataSource *)ds {
    if (self = [super init]) {
        _uid = uid;
        _ds = ds;
    }
    return self;
}

- (void)close {
    
}


@end
