//
//  NSFileManager+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSFileManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (CHExt)

- (NSURL *)URLForDocumentDirectory;
- (BOOL)fixDirectory:(NSURL *)path;
- (nullable NSURL *)URLForGroupId:(NSString *)groupId path:(NSString *)path;
- (nullable NSURL *)URLLinkForFile:(nullable NSURL *)filepath withName:(NSString *)filename;


@end

NS_ASSUME_NONNULL_END
