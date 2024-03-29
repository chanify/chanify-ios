//
//  CHConfig.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#ifndef __CHCONFIG_H__
#define __CHCONFIG_H__

#include <TargetConditionals.h>

#define kQuickStartURL                  "https://www.chanify.net/quickstart.html"
#define kUsageManualURL                 "https://github.com/chanify/chanify"
#define kCHPrivacyURL                   "https://www.chanify.net/privacy.html"
#define kCHAppStoreURL                  "itms-apps://itunes.apple.com/app/id1531546573"
#define kCHWatchAppURL                  "itms-watchs://net.chanify.ios.watchkitapp"
#define kCHContactEmail                 "support@chanify.net"
#define kCHAppName                      "Chanify"
#define kCHAPIHostname                  "api.chanify.net"
#define kCHAppGroupName                 "group.net.chanify.share"
#define kCHAppWatchGroupName            "group.net.chanify.share.watch"
#define kCHAppWidgetGroupName           "group.net.chanify.share.widget"
#define kCHAppTimelineGroupName         "group.net.chanify.share.timeline"
#define kCHAppOSXGroupName              "P4XS4AVCLW.group.net.chanify.share.osx"
#define kCHDeviceSecKeyName             "net.chanify.device.key"
#define kCHUserSecKeyName               "net.chanify.user.key"
#define kCHDBDataName                   "data.db"
#define kCHDBNotificationServiceName    "notification-service.db"
#define kCHDBTimelineName               "timeline.db"
#define kCHDBWidgetName                 "widget.db"
#define kCHCodeFormatterLength          24
#define kCHMessageListPageSize          16
#define kCHMessageListDateDiff          300
#define kCHDefaultNotificationSoundID   1315
#define kCHWebFileCacheMaxN             64
#define kCHWebBasePath                  "files"
#define kCHWebFileDownloadTimeout       30
#define kCHNodeServerRequestTimeout     10
#define kCHNodeCanCipherVersion         "1.0.5"
#define kCHCodeFontName                 "Menlo-Regular"
#define kCHSecKeySizeInBits             256
#define kCHAesGcmKeyBytes               32
#define kCHAesGcmTagBytes               16
#define kCHAesGcmNonceBytes             12
#define kCHAnimateFastDuration          0.2
#define kCHAnimateMediumDuration        0.3
#define kCHAnimateSlowDuration          0.4
#define kCHLoadingDuration              0.6
#if DEBUG
#   define kCHNotificationSandbox       YES
#else
#   define kCHNotificationSandbox       NO  // TestFlight use production APNS.
#endif
#if TARGET_OS_OSX
#   define kCHDBFileProtectionFlags     0
#   define kCHAppKeychainName           "P4XS4AVCLW.net.chanify.keychain.osx"
#else
#   define kCHAppKeychainName           "P4XS4AVCLW.net.chanify.keychain"
#   define kCHDBFileProtectionFlags     SQLITE_OPEN_FILEPROTECTION_COMPLETEUNTILFIRSTUSERAUTHENTICATION
#endif

#endif /* __CHCONFIG_H__ */
