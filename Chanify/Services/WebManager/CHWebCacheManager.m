//
//  CHWebCacheManager.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHWebCacheManager.h"

@interface CHWebCacheManager ()

@property (nonatomic, assign) NSUInteger totalAllocatedFileSize;

@end

@implementation CHWebCacheManager

- (instancetype)initWithFileBase:(NSURL *)fileBaseDir {
    if (self = [super init]) {
        _uid = nil;
        _fileBaseDir = fileBaseDir;
        _dataCache = [NSCache new];
        _totalAllocatedFileSize = 0;
        self.dataCache.countLimit = kCHWebFileCacheMaxN;
        [NSFileManager.defaultManager fixDirectory:self.fileBaseDir];
    }
    return self;
}

- (NSUInteger)allocatedFileSize {
    if (_totalAllocatedFileSize <= 0) {
        NSUInteger size = 0;
        NSArray *fieldKeys = @[NSURLIsRegularFileKey, NSURLTotalFileAllocatedSizeKey];
        NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:self.fileBaseDir includingPropertiesForKeys:fieldKeys options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
        for (NSURL *url in enumerator) {
            NSDictionary *fields = [url resourceValuesForKeys:fieldKeys error:nil];
            if ([[fields valueForKey:NSURLIsRegularFileKey] boolValue]) {
                size += [[fields valueForKey:NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
            }
        }
        _totalAllocatedFileSize = size;
    }
    return _totalAllocatedFileSize;
}

- (void)notifyAllocatedFileSizeChanged:(NSURL *)filepath {
    @weakify(self);
    dispatch_main_async(^{
        if (self->_totalAllocatedFileSize > 0) {
            @strongify(self);
            NSNumber *value = nil;
            if ([filepath getResourceValue:&value forKey:NSURLTotalFileAllocatedSizeKey error:nil]) {
                self->_totalAllocatedFileSize += [value unsignedIntegerValue];
            }
        }
        [self sendNotifyWithSelector:@selector(webCacheAllocatedFileSizeChanged:) withObject:self];
    });
}

- (void)setNeedUpdateAllocatedFileSize {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        self->_totalAllocatedFileSize = 0;
        [self sendNotifyWithSelector:@selector(webCacheAllocatedFileSizeChanged:) withObject:self];
    });
}

- (void)removeWithURLs:(NSArray<NSURL *> *)urls {
}

- (NSDictionary *)infoWithURL:(NSURL *)url {
    return @{};
}

- (NSDirectoryEnumerator *)fileEnumerator {
    return [NSFileManager.defaultManager enumeratorAtURL:self.fileBaseDir includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
}


@end
