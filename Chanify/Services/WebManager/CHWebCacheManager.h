//
//  CHWebCacheManager.h
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHWebCacheManager;

typedef void (^CHWebCacheManagerRemoveBlock)(NSUInteger count);

@protocol CHWebCacheManagerDelegate <NSObject>
- (void)webCacheAllocatedFileSizeChanged:(CHWebCacheManager *)manager;
@end

@interface CHWebCacheManager : CHManager<id<CHWebCacheManagerDelegate>>

@property (nonatomic, nullable, strong) NSString *uid;
@property (nonatomic, readonly, strong) NSURL *fileBaseDir;
@property (nonatomic, readonly, strong) NSCache *dataCache;
@property (nonatomic, assign) NSUInteger allocatedFileSize;

- (instancetype)initWithFileBase:(NSURL *)fileBaseDir;
- (void)notifyAllocatedFileSizeChanged:(NSURL *)filepath;
- (void)setNeedUpdateAllocatedFileSize;
- (void)removeWithURLs:(NSArray<NSURL *> *)urls;
- (void)removeWithDate:(NSDate *)limit completion:(nullable CHWebCacheManagerRemoveBlock)completion;
- (NSDictionary *)infoWithURL:(NSURL *)url;
- (NSDirectoryEnumerator *)fileEnumerator;


@end

NS_ASSUME_NONNULL_END
