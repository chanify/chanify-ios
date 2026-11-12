#import <Foundation/Foundation.h>
@interface WKExtension : NSObject
@property (class, readonly) WKExtension *sharedExtension;
- (void)registerForRemoteNotifications;
@end
