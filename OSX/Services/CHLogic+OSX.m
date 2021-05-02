//
//  CHLogic+OSX.m
//  OSX
//
//  Created by WizJin on 2021/5/2.
//

#import "CHLogic+OSX.h"
#import <AppKit/AppKit.h>
#import "CHNotification.h"

@interface CHLogic () <CHNotificationMessageDelegate>

@end

@implementation CHLogic

+ (instancetype)shared {
    static CHLogic *logic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logic = [CHLogic new];
    });
    return logic;
}

- (instancetype)init {
    if (self = [super initWithAppGroup:@kCHAppOSXGroupName]) {
        CHNotification.shared.delegate = self;
    }
    return self;
}

#pragma mark - CHNotificationMessageDelegate
- (void)registerForRemoteNotifications {
    dispatch_main_async(^{
        [NSApplication.sharedApplication registerForRemoteNotifications];
    });
}

- (void)receiveNotification:(UNNotification *)notification {
    //[self recivePushMessage:notification.request.content.userInfo];
}

- (void)receiveNotificationResponse:(UNNotificationResponse *)response {
//    NSString *mid = nil;
//    NSDictionary *info = response.notification.request.content.userInfo;
//    NSString *uid = [CHMessageModel parsePacket:info mid:&mid data:nil];
//    if (uid.length > 0 && mid.length > 0) {
//        CHLogI("Launch with message %u", mid);
//        [self recivePushMessage:info];
//        CHMessageModel *model = [self.userDataSource messageWithMID:mid];
//        if (model.channel.length > 0) {
//            NSString *cid = model.channel.base64;
//            dispatch_main_async(^{
//                [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": cid, @"singleton": @YES, @"show": @"detail" }];
//            });
//        }
//    }
}


@end
