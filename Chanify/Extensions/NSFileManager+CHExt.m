//
//  NSFileManager+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSFileManager+CHExt.h"

@implementation NSFileManager (CHExt)

- (NSURL *)URLForDocumentDirectory {
    return [[self URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)URLForLibraryDirectory {
    return [[self URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)fixDirectory:(NSURL *)path {
    BOOL isDirectory = NO;
    NSString *dirpath = path.path;
    if ([self fileExistsAtPath:dirpath isDirectory:&isDirectory]) {
        if (isDirectory) {
            return YES;
        } else {
            [self removeItemAtPath:dirpath error:nil];
        }
    }
    return [self createDirectoryAtPath:dirpath withIntermediateDirectories:YES attributes:nil error:nil];
}

- (nullable NSURL *)URLForGroupId:(NSString *)groupId path:(NSString *)path {
    NSURL *url = [self containerURLForSecurityApplicationGroupIdentifier:groupId];
    if (url != nil) {
        return [url  URLByAppendingPathComponent:path];
    }
    return nil;
}

- (nullable NSURL *)URLLinkForFile:(nullable NSURL *)filepath withName:(NSString *)filename {
    NSURL *url = nil;
    if (filename.length > 0) {
        if ([self isReadableFileAtPath:filepath.path]) {
            NSURL *link = [self.temporaryDirectory URLByAppendingPathComponent:filename];
            if ([self contentsEqualAtPath:filepath.path andPath:link.path]) {
                url = link;
            } else {
                [self removeItemAtURL:link error:nil];
                NSError *error = nil;
                [self linkItemAtURL:filepath toURL:link error:&error];
                if (error == nil) {
                    url = link;
                }
            }
        }
    }
    return url;
}


@end
