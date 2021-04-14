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


@end
