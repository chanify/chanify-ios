#import <UserNotifications/UserNotifications.h>
#import <objc/runtime.h>
#import "CHNotification.h"
#import "CHDevice.h"

static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}

// Replace only the notification center transport. Never request real permission
// or read/remove the user's delivered notifications.
@interface TestCenter : NSObject
@property (weak) id delegate;
@property NSUInteger removals;
@end
@implementation TestCenter
- (void)setNotificationCategories:(NSSet *)categories {}
- (void)getNotificationSettingsWithCompletionHandler:(void (^)(UNNotificationSettings *))completion {
    // No async permission state is needed to verify delivery retention.
}
- (void)removeAllDeliveredNotifications { self.removals++; }
@end
static TestCenter *center;
static id currentTestCenter(id self, SEL selector) { return center; }
@implementation CHDevice
+ (instancetype)shared { static CHDevice *device; if (!device) device = [CHDevice new]; return device; }
- (CHDeviceType)type { return CH_TEST_WATCH ? CHDeviceTypeWatchOS : CHDeviceTypeIOS; }
@end
@implementation NSString (TestLocalization)
- (NSString *)localized { return self; }
@end
@implementation CHManager
- (void)sendNotifyWithSelector:(SEL)action {}
@end
@interface CHNotification (TestAccess)
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completion;
@end
@interface TestDelegate : NSObject <CHNotificationMessageDelegate>
@property NSUInteger deliveries;
@end
@implementation TestDelegate
- (void)registerForRemoteNotifications {}
- (void)receiveNotification:(UNNotification *)notification { self.deliveries++; }
- (void)receiveNotificationResponse:(UNNotificationResponse *)response {}
@end
int main(void) { @autoreleasepool {
    center = [TestCenter new];
    Method method = class_getClassMethod(UNUserNotificationCenter.class, @selector(currentNotificationCenter));
    method_setImplementation(method, (IMP)currentTestCenter);
    CHNotification *notification = [CHNotification new];
    TestDelegate *delegate = [TestDelegate new];
    notification.delegate = delegate;
    [notification updateStatus];
    check(center.removals == (CH_TEST_WATCH ? 0 : 1), @"Watch activation preserves delivered notifications; iOS retains its existing behavior");
    __block NSUInteger completions = 0;
    __block UNNotificationPresentationOptions options = 0;
    [notification userNotificationCenter:(id)center willPresentNotification:nil withCompletionHandler:^(UNNotificationPresentationOptions result) {
        completions++; options = result;
    }];
    check(delegate.deliveries == 1 && completions == 1, @"foreground delivery forwards to delegate and completes exactly once");
    UNNotificationPresentationOptions expected = CH_TEST_WATCH ?
        (UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList | UNNotificationPresentationOptionSound) : 0;
    check(options == expected, @"Watch requests visible foreground delivery; iOS presentation is unchanged");
    puts(CH_TEST_WATCH ? "PASS: Watch notification retention and foreground presentation" : "PASS: iOS notification behavior preserved");
} return 0; }
