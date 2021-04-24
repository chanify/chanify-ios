//
//  CHDevice.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHDevice.h"
#if TARGET_OS_WATCH
#   import <WatchKit/WKInterfaceDevice.h>
#elif TARGET_OS_IPHONE
#   import <UIKit/UIDevice.h>
#   import <UIKit/UIScreen.h>
#endif
#import <sys/sysctl.h>

@implementation CHDevice

+ (instancetype)shared {
    static CHDevice *device;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = [CHDevice new];
    });
    return device;
}

- (instancetype)init {
    if (self = [super init]) {
        NSBundle *bundle = NSBundle.mainBundle;
        _app = @kCHAppName;
        _bundle = [bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        _version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _build = [[bundle objectForInfoDictionaryKey:@"CFBundleVersion"] intValue];
        _model = get_sysctl("hw.machine");
#if TARGET_OS_WATCH
        WKInterfaceDevice *device = WKInterfaceDevice.currentDevice;
        _scale = device.screenScale;
        _name = device.name;
        _type = CHDeviceTypeWatchOS;
        _osInfo = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];
#elif TARGET_OS_IPHONE
        UIDevice *device = UIDevice.currentDevice;
        _scale = UIScreen.mainScreen.scale;
        _name = device.name;
        _type = CHDeviceTypeIOS;
        _osInfo = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];
#endif
        CHLogI("%s version: %s(%d) %s/%s.", self.app.cstr, self.version.cstr, self.build, self.model.cstr, self.osInfo.cstr);
        _key = [CHSecKey secKeyWithName:@kCHDeviceSecKeyName device:YES created:YES];
        _uuid = self.key.uuid;
        _userAgent = [NSString stringWithFormat:@"%@/%@-%d (%@; %@; Scale/%0.2f)", self.app, self.version, self.build, self.model, self.osInfo, self.scale];
        CHLogI("Device uuid: %s", self.uuid.hex.cstr);
    }
    return self;
}

#pragma mark - Private Methods
static inline NSString *get_sysctl(const char *name) {
    char buffer[512] = { 0 };
    size_t size = sizeof(buffer);
    sysctlbyname(name, buffer, &size, NULL, 0);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}


@end
