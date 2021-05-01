//
//  CHNotification+Badge.m
//  Chanify
//
//  Created by WizJin on 2021/4/24.
//

#import "CHNotification+Badge.h"
#import <UIKit/UIApplication.h>

@implementation CHNotification (Badge)

- (NSUInteger)notificationBadge {
    return UIApplication.sharedApplication.applicationIconBadgeNumber;
}

- (void)setNotificationBadge:(NSUInteger)notificationBadge {
    UIApplication.sharedApplication.applicationIconBadgeNumber = notificationBadge;
}


@end
