#import <Foundation/Foundation.h>
@class CHNSDataSource;
@interface CHTestUser : NSObject
@property (nonatomic, copy) NSString *uid;
@end
@interface CHLogic : NSObject
@property (class, nonatomic, readonly) CHLogic *shared;
@property (nonatomic, strong) CHTestUser *me;
@property (nonatomic, strong) CHNSDataSource *nsDataSource;
@end
