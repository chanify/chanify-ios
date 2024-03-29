//
//  CHWebFileManager.h
//  Chanify
//
//  Created by WizJin on 2021/4/10.
//

#import "CHWebCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebFileItem <NSObject>

- (void)webFileUpdated:(nullable NSURL *)item fileURL:(nullable NSString *)fileURL;
- (void)webFileProgress:(double)progress fileURL:(nullable NSString *)fileURL;

@end

@interface CHWebFileManager : CHWebCacheManager

+ (instancetype)webFileManagerWithURL:(NSURL *)fileBaseDir;
- (void)close;
- (void)loadFileURL:(nullable NSString *)fileURL filename:(nullable NSString *)filename toItem:(id<CHWebFileItem>)item expectedSize:(uint64_t)expectedSize network:(BOOL)isNetwork;
- (void)resetFileURLFailed:(nullable NSString *)fileURL;
- (nullable NSURL *)loadLocalFileURL:(NSString *)fileURL filename:(NSString *)filename;


@end

NS_ASSUME_NONNULL_END
