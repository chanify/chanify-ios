//
//  NSString+CHNotification.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "NSString+CHLocalized.h"
#import <UserNotifications/NSString+UserNotifications.h>

@implementation NSString (CHLocalized)

- (NSString *)localized {
    return [NSString localizedUserNotificationStringForKey:(self ?: @"") arguments:nil];
}


@end
