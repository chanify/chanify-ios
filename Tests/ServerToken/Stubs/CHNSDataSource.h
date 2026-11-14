#import <Foundation/Foundation.h>
@interface CHNSDataSource : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSData *> *keys;
- (NSData *)keyForUID:(NSString *)uid;
@end
