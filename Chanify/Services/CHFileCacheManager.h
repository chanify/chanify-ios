//
//  CHFileCacheManager.h
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHFileCacheManager;

@protocol CHFileCacheManagerDelegate <NSObject>
- (void)fileCacheAllocatedFileSizeChanged:(CHFileCacheManager *)manager;
@end

@interface CHFileCacheManager : CHManager<id<CHFileCacheManagerDelegate>>

@property (nonatomic, nullable, strong) NSString *uid;
@property (nonatomic, readonly, strong) NSURL *fileBaseDir;
@property (nonatomic, readonly, strong) NSCache *dataCache;
@property (nonatomic, assign) NSUInteger allocatedFileSize;

- (instancetype)initWithFileBase:(NSURL *)fileBaseDir;
- (void)notifyAllocatedFileSizeChanged:(NSURL *)filepath;
- (void)setNeedUpdateAllocatedFileSize;
- (NSDirectoryEnumerator *)fileEnumerator;


@end

NS_ASSUME_NONNULL_END
