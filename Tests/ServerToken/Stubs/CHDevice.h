#import <Foundation/Foundation.h>
@interface CHDevice : NSObject
@property (class, nonatomic, readonly) CHDevice *shared;
@property (nonatomic, strong) NSData *uuid;
@end
