//
//  CHWebLinkManager.m
//  Chanify
//
//  Created by WizJin on 2021/4/3.
//

#import "CHWebLinkManager.h"
#import <LinkPresentation/LinkPresentation.h>
#import "CHUI.h"

@interface CHWebLinkTask : NSObject

@property (nonatomic, readonly, strong) NSURL *link;
@property (nonatomic, readonly, strong) NSHashTable<id<CHWebLinkItem>> *items;
@property (nonatomic, nullable, strong) LPMetadataProvider *provider;
@property (nonatomic, nullable, strong) NSMutableDictionary *result;

@end

@implementation CHWebLinkTask

- (instancetype)initWithURL:(NSURL *)link {
    if (self = [super init]) {
        _link = link;
        _provider = [LPMetadataProvider new];
        _items = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc {
    id result = self.result;
    NSHashTable<id<CHWebLinkItem>> *items = self.items;
    dispatch_main_async(^{
        for (id<CHWebLinkItem> item in items) {
            [item webLinkUpdated:result];
        }
    });
}

@end

@interface CHWebLinkManager ()

@property (nonatomic, readonly, strong) NSMutableDictionary<NSURL *, CHWebLinkTask *> *tasks;

@end

@implementation CHWebLinkManager

+ (instancetype)webLinkManagerWithURL:(NSURL *)fileBaseDir {
    return [[self.class alloc] initWithURL:fileBaseDir];
}

- (instancetype)initWithURL:(NSURL *)fileBaseDir {
    if (self = [super initWithFileBase:fileBaseDir]) {
        _tasks = [NSMutableDictionary new];
    }
    return self;
}

- (void)close {
    [self.tasks removeAllObjects];
    [self.dataCache removeAllObjects];
}

- (void)loadLinkFromURL:(nullable NSURL *)url toItem:(id<CHWebLinkItem>)item {
    if (url != nil) {
        NSString *scheme = url.scheme.lowercaseString;
        if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
            [item webLinkUpdated:@{
                @"host-desc": url.scheme ?: @"",
                @"icon": [CHImage systemImageNamed:@"link.circle"],
                @"title": @"URLScheme clicked".localized,
            }];
            return;
        }
        NSDictionary *data = [self loadLocalMeta:url];
        if (data != nil) {
            [item webLinkUpdated:data];
            return;
        }
        CHWebLinkTask *task = [self.tasks objectForKey:url];
        if (task != nil) {
            [task.items addObject:item];
        } else {
            task = [[CHWebLinkTask alloc] initWithURL:url];
            [self.tasks setObject:task forKey:url];
            [task.items addObject:item];
            [self asyncStartTask:task fileURL:[self url2Path:url]];
        }
    }
}

#pragma mark - Private Methods
- (NSURL *)url2Path:(NSURL *)url {
    NSString *name = [url.absoluteString dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
    return [self.fileBaseDir URLByAppendingPathComponent:name];
}

- (nullable id)loadLocalMeta:(nullable NSURL *)url {
    id res = nil;
    if (url != nil) {
        NSURL *filePath = [self url2Path:url];
        res = [self.dataCache objectForKey:filePath];
        if (res == nil) {
            res = [self decodeData:[NSData dataFromNoCacheURL:filePath]];
            if (res != nil) {
                [self.dataCache setObject:res forKey:filePath];
            }
        }
    }
    return res;
}

- (void)asyncStartTask:(CHWebLinkTask *)task fileURL:(NSURL *)fileURL {
    @weakify(self);
    [task.provider startFetchingMetadataForURL:task.link completionHandler:^(LPLinkMetadata *metadata, NSError *error) {
        @strongify(self);
        if (error == nil && metadata != nil) {
            NSMutableDictionary *result = [NSMutableDictionary new];
            if (metadata.title.length > 0) {
                [result setObject:metadata.title forKey:@"title"];
            }
            NSItemProvider *icon = metadata.iconProvider;
            if (icon != nil && icon.registeredTypeIdentifiers.count > 0) {
                @weakify(self);
                [icon loadItemForTypeIdentifier:icon.registeredTypeIdentifiers.firstObject options:0 completionHandler:^(NSData *item, NSError *error) {
                    @strongify(self);
                    if (error == nil && item.length > 0) {
                        CHImage *image = [CHImage imageWithData:item];
                        if (image != nil) {
                            [result setObject:image forKey:@"icon"];
                            [result setObject:item forKey:@"icon-raw"];
                        }
                    }
                    task.result = result;
                    [self finishTask:task toFile:fileURL];
                }];
                return;
            }
        }
        [self finishTask:task toFile:fileURL];
    }];
}

- (void)finishTask:(CHWebLinkTask *)task toFile:(NSURL *)fileURL {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        NSData *data = [self encodeData:task.result];
        if (data.length > 0 && [data writeToURL:fileURL atomically:YES]) {
            [self.dataCache setObject:task.result forKey:fileURL];
            [self notifyAllocatedFileSizeChanged:fileURL];
        }
        [self.tasks removeObjectForKey:task.link];
    });
}

- (nullable NSDictionary *)decodeData:(nullable NSData *)data {
    NSDictionary *res = nil;
    if (data.length > 0) {
        NSDictionary *dict = [NSDictionary dictionaryWithJSONData:data];
        if (dict.count > 0) {
            NSMutableDictionary *items = [NSMutableDictionary dictionaryWithDictionary:dict];
            NSData *icon = [NSData dataFromBase64:[items objectForKey:@"icon"]];
            [items removeObjectForKey:@"icon"];
            if (icon.length > 0) {
                CHImage *image = [CHImage imageWithData:icon];
                if (image != nil) {
                    [items setObject:image forKey:@"icon"];
                }
            }
            res = items;
        }
    }
    return res;
}

- (nullable NSData *)encodeData:(nullable NSMutableDictionary *)items {
    NSData *data = nil;
    if (items.count > 0) {
        NSMutableDictionary *save = [NSMutableDictionary dictionaryWithDictionary:items];
        [save removeObjectForKey:@"icon"];
        NSData *icon = [save objectForKey:@"icon-raw"];
        [save removeObjectForKey:@"icon-raw"];
        if (icon.length > 0) {
            [save setObject:icon.base64 forKey:@"icon"];
        }
        data = save.json;
        if (data.length > 0) {
            [items removeObjectForKey:@"icon-raw"];
        }
    }
    return data;
}


@end
