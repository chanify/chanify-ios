//
//  CHDevice.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHDevice.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
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
        _app = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        _bundle = [bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        _version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _build = [[bundle objectForInfoDictionaryKey:@"CFBundleVersion"] intValue];
        UIDevice *device = UIDevice.currentDevice;
        _scale = UIScreen.mainScreen.scale;
        _name = device.name;
        _model = get_sysctl("hw.machine");
        _osInfo = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];
        CHLogI("%s version: %s(%d) %s/%s.", self.app.cstr, self.version.cstr, self.build, self.model.cstr, self.osInfo.cstr);
        _key = [CHSecKey secKeyWithName:@kCHDeviceSecKeyName device:YES created:YES];
        _uuid = self.key.uuid;
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
