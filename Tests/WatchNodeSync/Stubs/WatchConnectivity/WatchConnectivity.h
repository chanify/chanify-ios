#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, WCSessionActivationState) { WCSessionActivationStateActivated = 2 };
@protocol WCSessionDelegate <NSObject>
@end
@interface WCSession : NSObject
@property (class, readonly) BOOL isSupported;
@property (class, readonly) WCSession *defaultSession;
@property (weak) id<WCSessionDelegate> delegate;
@property (strong) NSDictionary *receivedApplicationContext;
- (void)activateSession;
@end
