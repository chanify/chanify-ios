//
//  CHWebImageManager.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import "CHWebCacheManager.h"
#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebImageItem <NSObject>

- (void)webImageUpdated:(nullable CHImage *)item fileURL:(nullable NSString *)fileURL;
- (void)webImageProgress:(double)progress fileURL:(nullable NSString *)fileURL;

@end

@interface CHWebImageManager : CHWebCacheManager

+ (instancetype)webImageManagerWithURL:(NSURL *)fileBaseDir;
- (void)close;
- (void)loadImageURL:(nullable NSString *)fileURL toItem:(id<CHWebImageItem>)item expectedSize:(uint64_t)expectedSize;
- (void)resetFileURLFailed:(nullable NSString *)fileURL;
- (nullable CHImage *)loadLocalFile:(nullable NSString *)fileURL;
- (nullable NSURL *)localFileURL:(nullable NSString *)fileURL;


@end

NS_ASSUME_NONNULL_END
