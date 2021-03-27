//
//  CHWebFileManager.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebFileItem <NSObject>

- (BOOL)webFileUpdated:(nullable NSData *)data;

@end

@interface CHWebFileManager<Item: id<CHWebFileItem>> : NSObject

+ (instancetype)webFileManagerWithURL:(NSURL *)fileBaseDir userAgent:(NSString *)userAgent;
- (void)close;
- (void)loadFileURL:(nullable NSString *)fileURL toItem:(Item)item;


@end

NS_ASSUME_NONNULL_END
