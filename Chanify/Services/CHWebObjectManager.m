//
//  CHWebObjectManager.m
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import "CHWebObjectManager.h"
#import <UIKit/UIImage.h>
#import "CHUserDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic+iOS.h"
#import "CHDevice.h"
#import "CHToken.h"

@interface CHWebObjectTask : NSObject

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, strong) NSURL *localFile;
@property (nonatomic, readonly, assign) uint64_t expectedSize;
@property (nonatomic, readonly, assign) double lastProgress;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebObjectItem>> *items;
@property (nonatomic, nullable, strong) NSURLSessionDownloadTask *dataTask;
@property (nonatomic, nullable, strong) id result;

@end

@implementation CHWebObjectTask

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
    NSHashTable<id<CHWebObjectItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebObjectItem> item in items) {
            [item webObjectUpdated:result fileURL:fileURL];
        }
    });
}

- (void)updateProgress:(int64_t)progress expectedSize:(int64_t)expectedSize {
    NSHashTable<id<CHWebObjectItem>> *items = self.items;
    if (expectedSize <= 0) expectedSize = self.expectedSize;
    if (expectedSize <= 0) expectedSize = 10000;
    _lastProgress = MIN((double)progress/expectedSize, 1.0);
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        for (id<CHWebObjectItem> item in items) {
            [item webObjectProgress:self.lastProgress fileURL:self.fileURL];
        }
    });
}

- (void)addTaskItem:(id<CHWebObjectItem>)item {
    [self.items addObject:item];
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        [item webObjectProgress:self.lastProgress fileURL:self.fileURL];
    });
}


@end

@interface CHWebObjectManager () <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, readonly, strong) NSURL *fileBaseDir;
@property (nonatomic, readonly, strong) id<CHWebObjectDecoder> decoder;
@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, CHWebObjectTask *> *tasks;
@property (nonatomic, readonly, strong) NSMutableSet<NSString *> *failedTasks;
@property (nonatomic, readonly, strong) NSCache<NSString *, id> *dataCache;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation CHWebObjectManager

+ (instancetype)webObjectManagerWithURL:(NSURL *)fileBaseDir decoder:(id<CHWebObjectDecoder>)decoder {
    return [[self.class alloc] initWithURL:fileBaseDir decoder:decoder];
}

- (instancetype)initWithURL:(NSURL *)fileBaseDir decoder:(id<CHWebObjectDecoder>)decoder {
    if (self = [super init]) {
        _uid = nil;
        _fileBaseDir = fileBaseDir;
        _decoder = decoder;
        _tasks = [NSMutableDictionary new];
        _failedTasks = [NSMutableSet new];
        _dataCache = [NSCache new];
        _workerQueue = dispatch_queue_create_for(self, DISPATCH_QUEUE_SERIAL);
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration delegate:self delegateQueue:nil];
        [NSFileManager.defaultManager fixDirectory:self.fileBaseDir];
        self.dataCache.countLimit = 10;
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

- (void)loadFileURL:(nullable NSString *)fileURL toItem:(id<CHWebObjectItem>)item expectedSize:(uint64_t)expectedSize {
    if (fileURL.length > 0) {
        id data = [self loadLocalFile:fileURL];
        if (data != nil) {
            [item webObjectUpdated:data fileURL:fileURL];
            return;
        }
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            if ([self.failedTasks containsObject:fileURL]) {
                [item webObjectUpdated:nil fileURL:fileURL];
            } else {
                CHWebObjectTask *task = [self.tasks objectForKey:fileURL];
                if (task != nil) {
                    [task addTaskItem:item];
                } else {
                    task = [[CHWebObjectTask alloc] initWithFileURL:fileURL localFile:[self fileURL2Path:fileURL] expectedSize:expectedSize];
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

- (nullable id)loadLocalFile:(nullable NSString *)fileURL {
    id res = nil;
    if (fileURL.length > 0) {
        NSURL *url = [self fileURL2Path:fileURL];
        res = [self.dataCache objectForKey:url.absoluteString];
        if (res == nil) {
            res = [self.decoder webObjectDecode:[NSData dataFromNoCacheURL:url]];
            if (res != nil) {
                [self.dataCache setObject:res forKey:url.absoluteString];
            }
        }
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

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(nullable NSError *)error {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            CHWebObjectTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
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
            CHWebObjectTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                NSData *data = [NSData dataFromNoCacheURL:location];
                if (data.length > 0 && [data writeToURL:task.localFile atomically:YES]) {
                    task.localFile.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
                    task.result = [self.decoder webObjectDecode:data];
                    if (task.result != nil) {
                        [self.dataCache setObject:task.result forKey:task.localFile.absoluteString];
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
            CHWebObjectTask *task = [self.tasks valueForKey:downloadTask.taskDescription];
            if (task != nil) {
                [task updateProgress:totalBytesWritten expectedSize:totalBytesExpectedToWrite];
            }
        }
    });
}

#pragma mark - Private Methods
- (void)asyncStartTask:(CHWebObjectTask *)task {
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

@implementation CHWebImageDecoder

- (nullable id)webObjectDecode:(nullable NSData *)data {
    if (data.length > 0) {
        return [UIImage imageWithData:data];
    }
    return nil;
}


@end
