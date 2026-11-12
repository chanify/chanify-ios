// Only the transport is mocked; the production Watch sync and node model compile unchanged.
#import <Foundation/Foundation.h>
@interface CHTPNode : NSObject
@property (copy) NSString *nid, *name, *version, *endpoint, *icon;
@property (copy) NSData *pubkey;
@property uint64_t flags;
@end
@interface CHTPBlockItem : NSObject
@property (copy) NSString *token;
@end
@interface CHTPWatchConfig : NSObject
@property (copy) NSData *userKey;
@property (copy) NSArray *nodesArray, *blocklistArray;
+ (instancetype)parseFromData:(NSData *)data error:(NSError **)error;
@end
