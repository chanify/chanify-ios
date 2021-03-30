//
//  CHWebFileManager.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebFileItem <NSObject>

- (void)webFileUpdated:(nullable id)item;

@end

@protocol CHWebFileDecoder <NSObject>

- (nullable id)webFileDecode:(nullable NSData *)data;

@end

@interface CHWebImageFileDecoder : NSObject<CHWebFileDecoder>

@end


@interface CHWebFileManager<Item> : NSObject

@property (nonatomic, nullable, strong) NSString *uid;

+ (instancetype)webFileManagerWithURL:(NSURL *)fileBaseDir decoder:(id<CHWebFileDecoder>)decoder userAgent:(NSString *)userAgent;
- (void)close;
- (void)loadFileURL:(nullable NSString *)fileURL toItem:(id<CHWebFileItem>)item;
- (nullable Item)loadLocalFile:(nullable NSString *)fileURL;
- (nullable NSURL *)localFileURL:(nullable NSString *)fileURL;


@end

NS_ASSUME_NONNULL_END
