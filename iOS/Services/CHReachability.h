//
//  CHReachability.h
//  iOS
//
//  Created by WizJin on 2022/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *kReachabilityChangedNotification;

typedef NS_ENUM(NSInteger, CHNetworkStatus) {
    CHNetworkStatusNone = 0,
    CHNetworkStatusWiFi = 1,
    CHNetworkStatusWWAN = 2,
};

@interface CHReachability : NSObject

+ (instancetype)reachabilityForInternetConnection;
- (BOOL)startNotifier;
- (void)stopNotifier;
- (CHNetworkStatus)currentReachabilityStatus;


@end

NS_ASSUME_NONNULL_END
