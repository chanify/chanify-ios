//
//  CHWidgetManager.m
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/17.
//

#import "CHWidgetManager.h"
#import "CHUserModel.h"

@interface CHWidgetManager ()

@property (nonatomic, nullable, strong) NSString *uid;

@end

@implementation CHWidgetManager

+ (instancetype)shared {
    static CHWidgetManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CHWidgetManager new];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _uid = nil;
    }
    return self;
}

- (BOOL)reloadDB {
    CHUserModel *me = [CHUserModel modelWithKey:[CHSecKey secKeyWithName:@kCHUserSecKeyName device:NO created:NO]];
    NSString *uid = me.uid;
    if ([_uid isEqualToString:uid]) {
        _uid = uid;
    }
    return (self.uid.length > 0);
}


@end
