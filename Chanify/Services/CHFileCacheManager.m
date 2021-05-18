//
//  CHFileCacheManager.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHFileCacheManager.h"

@implementation CHFileCacheManager

- (instancetype)initWithFileBase:(NSURL *)fileBaseDir {
    if (self = [super init]) {
        _uid = nil;
        _fileBaseDir = fileBaseDir;
        [NSFileManager.defaultManager fixDirectory:self.fileBaseDir];
    }
    return self;
}

- (NSUInteger)allocatedFileSize {
    NSUInteger size = 0;
    NSArray *fieldKeys = @[NSURLIsRegularFileKey, NSURLTotalFileAllocatedSizeKey];
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:self.fileBaseDir includingPropertiesForKeys:fieldKeys options:0 errorHandler:nil];
    for (NSURL *url in enumerator) {
        NSDictionary *fields = [url resourceValuesForKeys:fieldKeys error:nil];
        if ([[fields valueForKey:NSURLIsRegularFileKey] boolValue]) {
            size += [[fields valueForKey:NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
        }
    }
    return size;
}


@end
