#import <Foundation/Foundation.h>
#define UNNotificationDismissActionIdentifier @"synthetic-dismiss"
@interface UNNotificationContent : NSObject
@property (strong) NSDictionary *userInfo;
@end
@interface UNNotificationRequest : NSObject
@property (strong) UNNotificationContent *content;
@end
@interface UNNotification : NSObject
@property (strong) UNNotificationRequest *request;
@end
@interface UNNotificationResponse : NSObject
@property (strong) UNNotification *notification;
@property (copy) NSString *actionIdentifier;
@end
