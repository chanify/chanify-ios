//
//  CHFileCacheManager.h
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHFileCacheManager : NSObject

@property (nonatomic, nullable, strong) NSString *uid;
@property (nonatomic, readonly, strong) NSURL *fileBaseDir;
@property (nonatomic, assign) NSUInteger allocatedFileSize;

- (instancetype)initWithFileBase:(NSURL *)fileBaseDir;


@end

NS_ASSUME_NONNULL_END
