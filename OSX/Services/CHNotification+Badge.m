//
//  CHNotification+Badge.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHNotification+Badge.h"
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import "CHRouter.h"

@implementation CHNotification (Badge)

static const char *kBadgeTagKey = "BadgeTagKey";

- (NSUInteger)notificationBadge {
    return [objc_getAssociatedObject(self, kBadgeTagKey) unsignedIntegerValue];
}

- (void)setNotificationBadge:(NSUInteger)notificationBadge {
    objc_setAssociatedObject(self, kBadgeTagKey, @(notificationBadge), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSString *badge;
    if (notificationBadge <= 0) {
        badge = @"";
    } else if (notificationBadge > 99) {
        badge = @"99+";
    } else {
        badge = [@(notificationBadge) stringValue];
    }
    CHRouter.shared.badgeText = badge;
}


@end
