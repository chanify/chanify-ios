//
//  CHDevice.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSecKey.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CHDeviceType) {
    CHDeviceTypeUnknown     = 0,
    CHDeviceTypeIOS         = 1,
    CHDeviceTypeWatchOS     = 2,
};

@interface CHDevice : NSObject

@property (nonatomic, readonly, strong) NSData *uuid;
@property (nonatomic, readonly, strong) NSString *app;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *bundle;
@property (nonatomic, readonly, strong) NSString *version;
@property (nonatomic, readonly, assign) uint32_t build;
@property (nonatomic, readonly, strong) NSString *osInfo;
@property (nonatomic, readonly, strong) NSString *model;
@property (nonatomic, readonly, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) CHSecKey *key;
@property (nonatomic, readonly, assign) CHDeviceType type;
@property (nonatomic, readonly, assign) double scale;

+ (instancetype)shared;


@end

NS_ASSUME_NONNULL_END
