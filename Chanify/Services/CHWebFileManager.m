//
//  CHWebFileManager.m
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import "CHWebFileManager.h"

@interface CHWebFileTask : NSObject

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebFileItem>> *items;
@property (nonatomic, nullable, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, nullable, strong) NSData *data;

@end

@implementation CHWebFileTask

- (instancetype)initWithFileURL:(NSString *)fileURL {
    if (self = [super init]) {
        _fileURL = fileURL;
        _items = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc {
    NSData *data = self.data;
    NSHashTable<id<CHWebFileItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebFileItem> item in items) {
            [item webFileUpdated:data];
        }
    });
}

@end

@interface CHWebFileManager ()

@property (nonatomic, readonly, strong) NSURL *fileBaseDir;
@property (nonatomic, readonly, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, CHWebFileTask *> *tasks;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation CHWebFileManager

+ (instancetype)webFileManagerWithURL:(NSURL *)fileBaseDir userAgent:(NSString *)userAgent {
    return [[self.class alloc] initWithURL:fileBaseDir userAgent:userAgent];
}

- (instancetype)initWithURL:(NSURL *)fileBaseDir userAgent:(NSString *)userAgent {
    if (self = [super init]) {
        _fileBaseDir = fileBaseDir;
        _userAgent = userAgent;
        _tasks = [NSMutableDictionary new];
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _workerQueue = dispatch_queue_create_for(self, DISPATCH_QUEUE_SERIAL);
        [NSFileManager.defaultManager fixDirectory:self.fileBaseDir];
    }
    return self;
}

- (void)dealloc {
    [self close];
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
    });
}

- (void)loadFileURL:(nullable NSString *)fileURL toItem:(id<CHWebFileItem>)item {
    if (fileURL.length > 0) {
        NSString *name = fileURL2Name(fileURL);
        NSURL *filePath = [self.fileBaseDir URLByAppendingPathComponent:name];
        NSData *data = [NSData dataFromNoCacheURL:filePath];
        if (data.length > 0) {
            [item webFileUpdated:data];
            return;
        }
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            CHWebFileTask *task = [self.tasks objectForKey:fileURL];
            if (task != nil) {
                [task.items addObject:item];
            } else {
                task = [[CHWebFileTask alloc] initWithFileURL:fileURL];
                [self.tasks setObject:task forKey:fileURL];
                [task.items addObject:item];
                [self asyncStartTask:task fileURL:filePath];
            }
        });
    }
}

#pragma mark - Private Methods
- (void)asyncStartTask:(CHWebFileTask *)task fileURL:(NSURL *)fileURL {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            NSURL *url = [NSURL URLWithString:task.fileURL];
            if (url != nil) {
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:kCHWebFileDownloadTimeout];
                [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
                @weakify(self);
                task.dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    @strongify(self);
                    if (error == nil) {
                        if (data.length > 0 && [data writeToURL:fileURL atomically:YES]) {
                            task.data = data;
                        }
                    }
                    [self.tasks removeObjectForKey:task.fileURL];
                }];
                [task.dataTask resume];
            }
        }
    });
}

static inline NSString *fileURL2Name(NSString *url) {
    return [url dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
}


@end
