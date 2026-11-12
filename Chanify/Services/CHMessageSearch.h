#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class FMDatabase;

// Search data is disposable. The messages table is always the source of truth.
@interface CHMessageSearch : NSObject
+ (BOOL)prepareTrackingInDatabase:(FMDatabase *)db;
+ (NSString *)normalizedText:(NSString *)text;
+ (NSString *)tokensForText:(NSString *)text;
- (instancetype)initWithURL:(NSURL *)url extractor:(NSDictionary<NSString *, NSString *> * _Nullable (^)(NSData *, NSString *))extractor;
- (void)requestIndexing;
- (void)setActive:(BOOL)active;
// Off by default; enabling never bypasses the new-message priority.
- (void)setHistoryIndexingEnabled:(BOOL)enabled;
- (void)rebuildIndex;
- (void)close;
- (void)search:(NSString *)query before:(nullable NSString *)mid limit:(NSUInteger)limit completion:(void (^)(NSArray<NSDictionary *> *results, BOOL more, BOOL incomplete, NSError * _Nullable error))completion;
// Cancellation also interrupts expensive FTS candidate sorting on the read connection.
- (void)cancelSearch;
@end
NS_ASSUME_NONNULL_END
