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
#import "CHToken.h"
#import "CHLogic.h"

@interface CHWebObjectTask : NSObject

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebObjectItem>> *items;
@property (nonatomic, nullable, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, nullable, strong) id result;

@end

@implementation CHWebObjectTask

- (instancetype)initWithFileURL:(NSString *)fileURL {
    if (self = [super init]) {
        _fileURL = fileURL;
        _items = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc {
    id result = self.result;
    NSHashTable<id<CHWebObjectItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebObjectItem> item in items) {
            [item webObjectUpdated:result];
        }
    });
}

@end

@interface CHWebObjectManager ()

@property (nonatomic, readonly, strong) NSURL *fileBaseDir;
@property (nonatomic, readonly, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) id<CHWebObjectDecoder> decoder;
@property (nonatomic, readonly, strong) NSURLSession *session;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, CHWebObjectTask *> *tasks;
@property (nonatomic, readonly, strong) NSCache<NSString *, id> *dataCache;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation CHWebObjectManager

+ (instancetype)webObjectManagerWithURL:(NSURL *)fileBaseDir decoder:(id<CHWebObjectDecoder>)decoder userAgent:(NSString *)userAgent {
    return [[self.class alloc] initWithURL:fileBaseDir decoder:decoder userAgent:userAgent];
}

- (instancetype)initWithURL:(NSURL *)fileBaseDir decoder:(id<CHWebObjectDecoder>)decoder userAgent:(NSString *)userAgent {
    if (self = [super init]) {
        _uid = nil;
        _fileBaseDir = fileBaseDir;
        _decoder = decoder;
        _userAgent = userAgent;
        _tasks = [NSMutableDictionary new];
        _dataCache = [NSCache new];
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        _workerQueue = dispatch_queue_create_for(self, DISPATCH_QUEUE_SERIAL);
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

- (void)loadFileURL:(nullable NSString *)fileURL toItem:(id<CHWebObjectItem>)item {
    if (fileURL.length > 0) {
        id data = [self loadLocalFile:fileURL];
        if (data != nil) {
            [item webObjectUpdated:data];
            return;
        }
        @weakify(self);
        dispatch_sync(self.workerQueue, ^{
            @strongify(self);
            CHWebObjectTask *task = [self.tasks objectForKey:fileURL];
            if (task != nil) {
                [task.items addObject:item];
            } else {
                task = [[CHWebObjectTask alloc] initWithFileURL:fileURL];
                [self.tasks setObject:task forKey:fileURL];
                [task.items addObject:item];
                [self asyncStartTask:task fileURL:[self fileURL2Path:fileURL]];
            }
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
        if ([NSFileManager.defaultManager isReadableFileAtPath:filepath.path]) {
            url = filepath;
        }
    }
    return url;
}

#pragma mark - Private Methods
- (void)asyncStartTask:(CHWebObjectTask *)task fileURL:(NSURL *)fileURL {
    @weakify(self);
    dispatch_async(self.workerQueue, ^{
        @strongify(self);
        if (self.session != nil) {
            NSURLRequest *request = [self webRequestWithFileURL:task.fileURL];
            if (request != nil) {
                @weakify(self);
                task.dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    @strongify(self);
                    if (error == nil) {
                        if (data.length > 0 && [data writeToURL:fileURL atomically:YES]) {
                            task.result = [self.decoder webObjectDecode:data];
                            if (task.result != nil) {
                                [self.dataCache setObject:task.result forKey:fileURL.absoluteString];
                            }
                        }
                    }
                    [self.tasks removeObjectForKey:task.fileURL];
                }];
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
            [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
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
