//
//  CHWebAudioManager.m
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHWebAudioManager.h"
#import "CHUserDataSource.h"
#import "CHAudioPlayer.h"
#import "CHNodeModel.h"
#import "CHLogic+iOS.h"
#import "CHDevice.h"
#import "CHToken.h"

@interface CHWebAudioTask : NSObject

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, strong) NSURL *localFile;
@property (nonatomic, readonly, assign) uint64_t expectedSize;
@property (nonatomic, readonly, assign) double lastProgress;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebAudioItem>> *items;
@property (nonatomic, nullable, strong) NSURLSessionDownloadTask *dataTask;
@property (nonatomic, nullable, strong) NSURL *result;

@end

@implementation CHWebAudioTask

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
    NSHashTable<id<CHWebAudioItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebAudioItem> item in items) {
            [item webAudioUpdated:result fileURL:fileURL];
        }
    });
}

- (void)updateProgress:(int64_t)progress expectedSize:(int64_t)expectedSize {
    NSHashTable<id<CHWebAudioItem>> *items = self.items;
    if (expectedSize <= 0) expectedSize = self.expectedSize;
    if (expectedSize <= 0) expectedSize = 10000;
    _lastProgress = MIN((double)progress/expectedSize, 1.0);
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        for (id<CHWebAudioItem> item in items) {
            [item webAudioProgress:self.lastProgress fileURL:self.fileURL];
        }
    });
}

- (void)addTaskItem:(id<CHWebAudioItem>)item {
    [self.items addObject:item];
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        [item webAudioProgress:self.lastProgress fileURL:self.fileURL];
    });
}

@end

@interface CHWebAudioManager () <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, CHWebAudioTask *> *tasks;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *failedTasks;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation CHWebAudioManager

+ (instancetype)webAudioManagerWithURL:(NSURL *)fileBaseDir {
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

- (void)loadAudioURL:(nullable NSString *)fileURL toItem:(id<CHWebAudioItem>)item expectedSize:(uint64_t)expectedSize {
    if (fileURL.length > 0) {
        NSURL *data = [self loadLocalFile:fileURL];
        if (data != nil) {
            [item webAudioUpdated:data fileURL:fileURL];
            return;
        }
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            if ([self.failedTasks containsObject:fileURL]) {
                [item webAudioUpdated:nil fileURL:fileURL];
            } else {
                CHWebAudioTask *task = [self.tasks objectForKey:fileURL];
                if (task != nil) {
                    [task addTaskItem:item];
                } else {
                    task = [[CHWebAudioTask alloc] initWithFileURL:fileURL localFile:[self fileURL2Path:fileURL] expectedSize:expectedSize];
                    [self.tasks setObject:task forKey:fileURL];
                    [task.items addObject:item];
                    [self asyncStartTask:task];
                }
            }
        });
    }
}

- (nullable NSURL *)loadLocalFile:(nullable NSString *)fileURL {
    id res = nil;
    if (fileURL.length > 0) {
        NSURL *local = [self fileURL2Path:fileURL];
        if ([self loadLocalURLDuration:local] != nil) {
            res = local;
        }
    }
    return res;
}

- (nullable NSNumber *)loadLocalURLDuration:(nullable NSURL *)url {
    NSNumber *res = nil;
    if (url != nil) {
        url = url.URLByResolvingSymlinksInPath;
        res = [self.dataCache objectForKey:url.absoluteString];
        if (res == nil) {
            if ([NSFileManager.defaultManager isReadableFileAtPath:url.path]) {
                res = @([CHAudioPlayer.shared durationForURL:url]);
            }
            if (res != nil) {
                [self.dataCache setObject:res forKey:url.absoluteString];
            }
        }
    }
    return res;
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
    CHAudioPlayer *audioPlayer = CHAudioPlayer.shared;
    if (audioPlayer.isPlaying) {
        NSURL *playURL = audioPlayer.currentURL;
        for (NSURL *url in urls) {
            if ([playURL isEqual:url.URLByResolvingSymlinksInPath]) {
                [audioPlayer stop];
                break;
            }
        }
    }
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
            CHWebAudioTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                task.result = nil;
                [self.failedTasks addObject:task.fileURL];
                [self.tasks removeObjectForKey:task.fileURL];
            }
        }
    });
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
                                      didFinishDownloadingToURL:(nonnull NSURL *)location {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            CHWebAudioTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                NSData *data = [NSData dataFromNoCacheURL:location];
                if (data.length > 0 && [data writeToURL:task.localFile atomically:YES]) {
                    task.localFile.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
                    task.result = task.localFile;
                    if (task.result != nil) {
                        [self.dataCache setObject:@([CHAudioPlayer.shared durationForURL:task.localFile]) forKey:task.localFile.absoluteString];
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
            CHWebAudioTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                [task updateProgress:totalBytesWritten expectedSize:totalBytesExpectedToWrite];
            }
        }
    });
}

#pragma mark - Private Methods
- (void)asyncStartTask:(CHWebAudioTask *)task {
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

- (NSURL *)fileURL2Path:(NSString *)fileURL {
    NSString *name = [fileURL dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
    return [self.fileBaseDir URLByAppendingPathComponent:name];
}


@end
