//
//  CHWebImageManager.m
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import "CHWebImageManager.h"
#import "CHUserDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic+iOS.h"
#import "CHDevice.h"
#import "CHToken.h"

@interface CHWebImageTask : NSObject

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, strong) NSURL *localFile;
@property (nonatomic, readonly, assign) uint64_t expectedSize;
@property (nonatomic, readonly, assign) double lastProgress;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebImageItem>> *items;
@property (nonatomic, nullable, strong) NSURLSessionDownloadTask *dataTask;
@property (nonatomic, nullable, strong) id result;

@end

@implementation CHWebImageTask

- (instancetype)initWithFileURL:(NSString *)fileURL localFile:(NSURL *)localFile expectedSize:(uint64_t)expectedSize {
    if (self = [super init]) {
        _fileURL = fileURL;
        _localFile = localFile;
        _expectedSize = expectedSize;
        _lastProgress = 0;
        _items = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc {
    id result = self.result;
    NSString *fileURL = self.fileURL;
    NSHashTable<id<CHWebImageItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebImageItem> item in items) {
            [item webImageUpdated:result fileURL:fileURL];
        }
    });
}

- (void)updateProgress:(int64_t)progress expectedSize:(int64_t)expectedSize {
    NSHashTable<id<CHWebImageItem>> *items = self.items;
    if (expectedSize <= 0) expectedSize = self.expectedSize;
    if (expectedSize <= 0) expectedSize = 10000;
    _lastProgress = MIN((double)progress/expectedSize, 1.0);
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        for (id<CHWebImageItem> item in items) {
            [item webImageProgress:self.lastProgress fileURL:self.fileURL];
        }
    });
}

- (void)addTaskItem:(id<CHWebImageItem>)item {
    [self.items addObject:item];
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        [item webImageProgress:self.lastProgress fileURL:self.fileURL];
    });
}


@end

@interface CHWebImageManager () <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, CHWebImageTask *> *tasks;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *failedTasks;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation CHWebImageManager

+ (instancetype)webImageManagerWithURL:(NSURL *)fileBaseDir {
    return [[self.class alloc] initWithURL:fileBaseDir];
}

- (instancetype)initWithURL:(NSURL *)fileBaseDir {
    if (self = [super initWithFileBase:fileBaseDir]) {
        _tasks = [NSMutableDictionary new];
        _failedTasks = [NSMutableSet new];
        _workerQueue = dispatch_queue_create_for(self, DISPATCH_QUEUE_SERIAL);
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)close {
    @weakify(self);
    dispatch_sync(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            [self.session invalidateAndCancel];
            _session = nil;
        }
        [self.tasks removeAllObjects];
        [self.dataCache removeAllObjects];
    });
}

- (void)loadImageURL:(nullable NSString *)fileURL toItem:(id<CHWebImageItem>)item expectedSize:(uint64_t)expectedSize {
    if (fileURL.length > 0) {
        CHImage *data = [self loadLocalFile:fileURL];
        if (data != nil) {
            [item webImageUpdated:data fileURL:fileURL];
            return;
        }
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            if ([self.failedTasks containsObject:fileURL]) {
                [item webImageUpdated:nil fileURL:fileURL];
            } else {
                CHWebImageTask *task = [self.tasks objectForKey:fileURL];
                if (task != nil) {
                    [task addTaskItem:item];
                } else {
                    task = [[CHWebImageTask alloc] initWithFileURL:fileURL localFile:[self fileURL2Path:fileURL] expectedSize:expectedSize];
                    [self.tasks setObject:task forKey:fileURL];
                    [task.items addObject:item];
                    [self asyncStartTask:task];
                }
            }
        });
    }
}

- (void)resetFileURLFailed:(nullable NSString *)fileURL {
    if (fileURL.length > 0) {
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            [self.failedTasks removeObject:fileURL];
        });
    }
}

- (nullable CHImage *)loadLocalFile:(nullable NSString *)fileURL {
    id res = nil;
    if (fileURL.length > 0) {
        res = [self loadLocalURL:[self fileURL2Path:fileURL]];
    }
    return res;
}

- (nullable NSURL *)localFileURL:(nullable NSString *)fileURL {
    NSURL *url = nil;
    if (fileURL.length > 0) {
        NSURL *filepath = [self fileURL2Path:fileURL];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        if ([fileManager isReadableFileAtPath:filepath.path]) {
            url = filepath;
        } else if ([fileManager fileExistsAtPath:filepath.path]) {
            filepath.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
            if ([fileManager isReadableFileAtPath:filepath.path]) {
                url = filepath;
            }
        }
    }
    return url;
}

- (void)removeWithURLs:(NSArray<NSURL *> *)urls {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        NSFileManager *fileManager = NSFileManager.defaultManager;
        for (NSURL *url in urls) {
            [self.dataCache removeObjectForKey:url.URLByResolvingSymlinksInPath.absoluteString];
            [fileManager removeItemAtURL:url error:nil];
        }
        [self setNeedUpdateAllocatedFileSize];
    });
}

- (NSDictionary *)infoWithURL:(NSURL *)url {
    NSDictionary *attrs = [url resourceValuesForKeys:@[NSURLCreationDateKey, NSURLFileAllocatedSizeKey] error:nil];
    NSMutableDictionary *info = [NSMutableDictionary new];
    id item = [self loadLocalURL:url.URLByResolvingSymlinksInPath];
    if (item != nil) {
        [info setValue:item forKey:@"data"];
    }
    id date = [attrs valueForKey:NSURLCreationDateKey];
    if (date != nil) {
        [info setValue:date forKey:@"date"];
    }
    id size = [attrs valueForKey:NSURLFileAllocatedSizeKey];
    if (size != nil) {
        [info setValue:size forKey:@"size"];
    }
    return info;
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(nullable NSError *)error {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            CHWebImageTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                task.result = nil;
                [self.failedTasks addObject:task.fileURL];
                [self.tasks removeObjectForKey:task.fileURL];
            }
        }
    });
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
                                      didFinishDownloadingToURL:(nonnull NSURL *)location {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            CHWebImageTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                NSData *data = [NSData dataFromNoCacheURL:location];
                if (data.length > 0 && [data writeToURL:task.localFile atomically:YES]) {
                    task.localFile.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
                    task.result = [self imageDecode:data];
                    if (task.result != nil) {
                        [self.dataCache setObject:task.result forKey:task.localFile.absoluteString];
                    }
                    [self notifyAllocatedFileSizeChanged:task.localFile];
                }
                [self.tasks removeObjectForKey:task.fileURL];
            }
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            CHWebImageTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                [task updateProgress:totalBytesWritten expectedSize:totalBytesExpectedToWrite];
            }
        }
    });
}

#pragma mark - Private Methods
- (void)asyncStartTask:(CHWebImageTask *)task {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            NSURLRequest *request = [self webRequestWithFileURL:task.fileURL];
            if (request != nil) {
                task.dataTask = [self.session downloadTaskWithRequest:request];
                task.dataTask.taskDescription = task.fileURL;
                [task updateProgress:1 expectedSize:0];
                [task.dataTask resume];
            }
        }
    });
}

- (nullable NSMutableURLRequest *)webRequestWithFileURL:(NSString *)fileURL {
    NSMutableURLRequest *request = nil;
    if (fileURL.length > 0) {
        if ([fileURL characterAtIndex:0] != '!') {
            request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fileURL] cachePolicy:0 timeoutInterval:kCHWebFileDownloadTimeout];
        } else {
            NSRange index = [fileURL rangeOfString:@":"];
            if (index.location != NSNotFound) {
                index.length = index.location - 1;
                index.location = 1;
                NSString *nodeId = [fileURL substringWithRange:index];
                NSString *path = [fileURL substringFromIndex:index.length + 2];
                CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:nodeId];
                if (node != nil) {
                    NSURL *url = [[NSURL URLWithString:node.endpoint] URLByAppendingPathComponent:path];
                    request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:kCHWebFileDownloadTimeout];
                    CHToken *token = [CHToken tokenWithTimeOffset:3600];
                    token.node = node;
                    token.dataHash = [path dataUsingEncoding:NSUTF8StringEncoding];
                    [request setValue:[token formatString:node.nid direct:YES] forHTTPHeaderField:@"Token"];
                }
            }
        }
        if (request != nil) {
            [request setValue:CHDevice.shared.userAgent forHTTPHeaderField:@"User-Agent"];
        }
    }
    return request;
}

- (nullable CHImage *)loadLocalURL:(nullable NSURL *)url {
    id res = nil;
    if (url != nil) {
        res = [self.dataCache objectForKey:url.absoluteString];
        if (res == nil) {
            res = [self imageDecode:[NSData dataFromNoCacheURL:url]];
            if (res != nil) {
                [self.dataCache setObject:res forKey:url.absoluteString];
            }
        }
    }
    return res;
}

- (NSURL *)fileURL2Path:(NSString *)fileURL {
    NSString *name = [fileURL dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
    return [self.fileBaseDir URLByAppendingPathComponent:name];
}

- (nullable CHImage *)imageDecode:(nullable NSData *)data {
    if (data.length > 0) {
        return [CHImage imageWithData:data];
    }
    return nil;
}


@end
