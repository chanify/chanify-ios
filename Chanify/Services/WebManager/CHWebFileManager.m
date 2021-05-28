//
//  CHWebFileManager.m
//  Chanify
//
//  Created by WizJin on 2021/4/10.
//

#import "CHWebFileManager.h"
#import "CHUserDataSource.h"
#import "CHLogic+iOS.h"
#import "CHNodeModel.h"
#import "CHDevice.h"
#import "CHToken.h"

@interface CHWebFileTask : NSObject

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, strong) NSString *filename;
@property (nonatomic, readonly, strong) NSURL *localFile;
@property (nonatomic, readonly, assign) uint64_t expectedSize;
@property (nonatomic, readonly, assign) double lastProgress;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebFileItem>> *items;
@property (nonatomic, nullable, strong) NSURLSessionDownloadTask *dataTask;
@property (nonatomic, nullable, strong) NSURL *result;

@end

@implementation CHWebFileTask

- (instancetype)initWithFileURL:(NSString *)fileURL filename:(NSString *)filename localFile:(NSURL *)localFile expectedSize:(uint64_t)expectedSize {
    if (self = [super init]) {
        _fileURL = fileURL;
        _filename = filename;
        _localFile = localFile;
        _expectedSize = expectedSize;
        _lastProgress = 0;
        _items = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc {
    NSURL *result = self.result;
    NSString *fileURL = self.fileURL;
    NSHashTable<id<CHWebFileItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebFileItem> item in items) {
            [item webFileUpdated:result fileURL:fileURL];
        }
    });
}

- (void)updateProgress:(int64_t)progress expectedSize:(int64_t)expectedSize {
    NSHashTable<id<CHWebFileItem>> *items = self.items;
    if (expectedSize <= 0) expectedSize = self.expectedSize;
    if (expectedSize <= 0) expectedSize = 10000;
    _lastProgress = MIN((double)progress/expectedSize, 1.0);
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        for (id<CHWebFileItem> item in items) {
            [item webFileProgress:self.lastProgress fileURL:self.fileURL];
        }
    });
}

- (void)addTaskItem:(id<CHWebFileItem>)item {
    [self.items addObject:item];
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        [item webFileProgress:self.lastProgress fileURL:self.fileURL];
    });
}

@end

@interface CHWebFileManager () <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, CHWebFileTask *> *tasks;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *failedTasks;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation CHWebFileManager

+ (instancetype)webFileManagerWithURL:(NSURL *)fileBaseDir{
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

- (void)loadFileURL:(nullable NSString *)fileURL filename:(nullable NSString *)filename toItem:(id<CHWebFileItem>)item expectedSize:(uint64_t)expectedSize  {
    if (filename.length <= 0) filename = @"file";
    if (fileURL.length > 0) {
        NSURL *url = [self loadLocalFileURL:fileURL filename:filename];
        if (url != nil) {
            [item webFileUpdated:url fileURL:fileURL];
            return;
        }
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            if ([self.failedTasks containsObject:fileURL]) {
                [item webFileUpdated:nil fileURL:fileURL];
            } else {
                CHWebFileTask *task = [self.tasks objectForKey:fileURL];
                if (task != nil) {
                    [task addTaskItem:item];
                } else {
                    task = [[CHWebFileTask alloc] initWithFileURL:fileURL filename:filename localFile:[self fileURL2Path:fileURL filename:filename] expectedSize:expectedSize];
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

- (void)removeWithURLs:(NSArray<NSURL *> *)urls {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        NSFileManager *fm = NSFileManager.defaultManager;
        for (NSURL *url in urls) {
            NSURL *dir = url.URLByResolvingSymlinksInPath;
            if ([dir.absoluteString hasPrefix:self.fileBaseDir.absoluteString]) {
                [self.dataCache removeObjectForKey:dir.absoluteString];
                [fm removeItemAtURL:url.URLByDeletingLastPathComponent error:nil];
            }
        }
        [self setNeedUpdateAllocatedFileSize];
    });
}

- (NSDictionary *)infoWithURL:(NSURL *)url {
    NSDictionary *attrs = [url resourceValuesForKeys:@[NSURLNameKey, NSURLCreationDateKey, NSURLFileAllocatedSizeKey] error:nil];
    NSMutableDictionary *info = [NSMutableDictionary new];
    id name = [attrs valueForKey:NSURLNameKey];
    if (name != nil) {
        [info setValue:name forKey:@"name"];
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

- (nullable NSURL *)loadLocalFileURL:(NSString *)fileURL filename:(NSString *)filename {
    NSString *key = [fileURL stringByAppendingPathComponent:filename];
    NSURL *url = [self.dataCache objectForKey:key];
    if (url == nil) {
        url = [self fileURL2Path:fileURL filename:filename];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        if ([fileManager isReadableFileAtPath:url.path]) {
            [self.dataCache setObject:url forKey:key];
        } else {
            url = nil;
        }
    }
    return url;
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(nullable NSError *)error {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            CHWebFileTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
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
            CHWebFileTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                NSData *data = [NSData dataFromNoCacheURL:location];
                if (data.length > 0) {
                    NSURL *fileURL = task.localFile;
                    NSURL *dir = fileURL.URLByDeletingLastPathComponent;
                    NSFileManager *fileManager = NSFileManager.defaultManager;
                    if ([fileManager fixDirectory:dir] && [data writeToURL:fileURL atomically:YES]) {
                        task.result = fileURL;
                        [self.dataCache setObject:task.result forKey:[task.fileURL stringByAppendingPathComponent:task.filename]];
                        [self notifyAllocatedFileSizeChanged:fileURL];
                    }
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
            CHWebFileTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                [task updateProgress:totalBytesWritten expectedSize:totalBytesExpectedToWrite];
            }
        }
    });
}

#pragma mark - Private Methods
- (void)asyncStartTask:(CHWebFileTask *)task {
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

- (NSURL *)fileURL2Path:(NSString *)fileURL filename:(NSString *)filename {
    NSString *name = [fileURL dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
    return [[self.fileBaseDir URLByAppendingPathComponent:name] URLByAppendingPathComponent:filename];
}


@end
